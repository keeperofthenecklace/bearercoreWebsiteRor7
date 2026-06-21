module Api
  module V2
    # Inbound RTGS boundary. A commercial bank's RTGS network posts an ISO 20022
    # pacs.009 (FI credit transfer) here when it moves fiat liquidity to the
    # Central Bank settlement account. We audit the raw body, enforce idempotency
    # on (BizMsgIdr, UETR), and hand off to RtgsInboundService which materialises
    # a pre-cleared TradeClaim that flows to the Qt6 SELECT SOURCE dropdown via
    # the existing clearance-broadcast pipeline.
    class RtgsWebhooksController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_rtgs_sender

      # POST /api/v2/rtgs/inbound/pacs009
      def receive_pacs009
        payload = RtgsInboundPayload.create!(
          raw_xml:           request.raw_post,
          client_ip_address: request.remote_ip,
          tls_fingerprint:   request.headers["X-SSL-Client-Fingerprint"].presence || "UNKNOWN"
        )

        doc = Nokogiri::XML(payload.raw_xml)
        doc.remove_namespaces!

        biz_msg_idr = doc.at_xpath("//BizMsgIdr")&.text&.strip
        uetr        = doc.at_xpath("//UETR")&.text&.strip

        if biz_msg_idr.blank? || uetr.blank?
          payload.destroy
          return render json: { error: "Missing ISO 20022 identifiers (BizMsgIdr / UETR)" },
                        status: :bad_request
        end

        # Fast-path idempotency check (the unique index is the authoritative guard
        # and is caught below for the concurrent-submit race).
        if Pacs009Message.exists?(biz_msg_idr: biz_msg_idr, uetr: uetr)
          return render json: { status: "DUPLICATE_IGNORED" }, status: :ok
        end

        claim = nil
        ActiveRecord::Base.transaction do
          amount_node = doc.at_xpath("//IntrBkSttlmAmt")

          msg = Pacs009Message.create!(
            rtgs_inbound_payload: payload,
            biz_msg_idr:       biz_msg_idr,
            uetr:              uetr,
            msg_def_idr:       doc.at_xpath("//MsgDefIdr")&.text&.strip.presence || "pacs.009.001.08",
            cre_dt:            (doc.at_xpath("//CreDt")&.text || doc.at_xpath("//CreDtTm")&.text).presence,
            end_to_end_id:     doc.at_xpath("//EndToEndId")&.text&.strip,
            sender_bic:        bic(doc, "//Dbtr//FinInstnId//BICFI", "//InstgAgt//FinInstnId//BICFI"),
            receiver_bic:      bic(doc, "//Cdtr//FinInstnId//BICFI", "//InstdAgt//FinInstnId//BICFI"),
            currency_code:     amount_node&.attr("Ccy"),
            settlement_amount: amount_node&.text&.strip,  # decimal column casts the string
            value_date:        doc.at_xpath("//IntrBkSttlmDt")&.text.presence,
            processing_state:  "received"
          )

          claim = IssuancePipeline::RtgsInboundService.new(msg).call
        end

        render json: {
          status:          "SUCCESS_CLEARED",
          claim_reference: claim&.reference,
          claim_status:    claim&.status
        }, status: :created
      rescue ActiveRecord::RecordNotUnique
        render json: { status: "DUPLICATE_IGNORED" }, status: :ok
      rescue => e
        Rails.logger.error "[RtgsWebhooksController] #{e.class}: #{e.message}"
        render json: { error: "RTGS pipeline failure", detail: e.message },
               status: :unprocessable_entity
      end

      private

      def bic(doc, *xpaths)
        xpaths.each do |xp|
          val = doc.at_xpath(xp)&.text&.strip
          return val if val.present?
        end
        nil
      end

      # mTLS (enforced in production via the downstream proxy) + shared secret.
      def authenticate_rtgs_sender
        if Rails.env.production? && request.headers["X-SSL-Client-Verify"] != "SUCCESS"
          return render json: { error: "Mutual TLS authentication failed" }, status: :unauthorized
        end

        expected = ENV["RTGS_WEBHOOK_SECRET"].to_s
        provided = request.headers["X-RTGS-Signature"].to_s

        if expected.blank? ||
           !ActiveSupport::SecurityUtils.secure_compare(provided, expected)
          render json: { error: "Invalid RTGS gateway credentials" }, status: :unauthorized
        end
      end
    end
  end
end
