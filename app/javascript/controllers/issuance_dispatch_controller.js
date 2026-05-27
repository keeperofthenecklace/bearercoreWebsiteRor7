// app/javascript/controllers/issuance_dispatch_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["wrapper", "statusText", "actionFrame", "pinInput", "submitBtn"]

  connect() {
    this.operatorId = this.element.dataset.operatorId || "shared"
    this._setAwaitingState()
    this._initSubscription()
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
  }

  _initSubscription() {
    this.subscription = consumer.subscriptions.create(
      { channel: "OperatorTerminalChannel" },
      {
        received: (data) => {
          if (data.event === "sovereign_clearance_received") {
            this._transitionToCleared(data)
          }
        }
      }
    )
  }

  // ── State 1: Awaiting clearance ────────────────────────────────────────────
  _setAwaitingState() {
    if (this.hasWrapperTarget) {
      this.wrapperTarget.className = "pipeline-panel pipeline-awaiting"
    }
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.innerHTML = `
        <div class="pipeline-line dim">⚡ ISSUANCE DISPATCH PIPELINE</div>
        <div class="pipeline-line dim">──────────────────────────────────────</div>
        <div class="pipeline-line">Status: <span class="warn">⏳ AWAITING SUPERVISOR DESK VERIFICATION</span></div>
        <div class="pipeline-line dim">Message: Local workstation node is idling. Waiting for signed clearing token event...</div>
        <div class="pipeline-sep"></div>
        <div class="pipeline-box">🔒 LOCAL VAULT ENGINE LOCKED</div>
      `
    }
    if (this.hasActionFrameTarget) this.actionFrameTarget.innerHTML = ""
  }

  // ── State 2: Cleared & Active ──────────────────────────────────────────────
  _transitionToCleared(data) {
    if (this.hasWrapperTarget) {
      this.wrapperTarget.className = "pipeline-panel pipeline-cleared"
      this.wrapperTarget.classList.add("pipeline-flash")
      setTimeout(() => this.wrapperTarget.classList.remove("pipeline-flash"), 600)
    }

    if (this.hasStatusTextTarget) {
      this.statusTextTarget.innerHTML = `
        <div class="pipeline-line dim">⚡ ISSUANCE DISPATCH PIPELINE</div>
        <div class="pipeline-line dim">──────────────────────────────────────</div>
        <div class="pipeline-line">Status: <span class="ok">🟢 READY TO MINT (Sovereign Authorization Token Verified)</span></div>
        <div class="pipeline-line">Target Allocation: <strong>${data.total_amount} ${data.asset_code} Token Envelope</strong></div>
        <div class="pipeline-line dim">Corridor: ${data.corridor_display}</div>
        <div class="pipeline-line dim">Auth ID: ${data.authorization_id}</div>
      `
    }

    if (this.hasActionFrameTarget) {
      this.actionFrameTarget.innerHTML = `
        <div class="pin-auth-block">
          <label class="pin-label">Enter Secure Spend PIN:</label>
          <div class="pin-row">
            <input type="password" maxlength="4" placeholder="••••"
                   class="pin-input"
                   data-issuance-dispatch-target="pinInput"
                   data-action="input->issuance-dispatch#onPinInput" />
            <button class="btn-mint-execute" disabled
                    data-issuance-dispatch-target="submitBtn"
                    data-action="click->issuance-dispatch#onExecute">
              ⚡ EXECUTE CRYPTOGRAPHIC MINT
            </button>
          </div>
        </div>
      `
    }
  }

  // ── State 3: Processing ────────────────────────────────────────────────────
  _transitionToProcessing(authId, assetCode) {
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.innerHTML = `
        <div class="pipeline-line dim">⚡ ISSUANCE DISPATCH PIPELINE</div>
        <div class="pipeline-line dim">──────────────────────────────────────</div>
        <div class="pipeline-line">Status: <span class="processing">⚙ GENERATING DIGITAL CASH NOTE BLOCKS</span></div>
        <div class="pipeline-line">Progress: <span id="pipeline-progress-bar">[                                        ]   0%</span></div>
        <div class="pipeline-sep"></div>
        <div class="pipeline-line dim">&gt;&gt; Encapsulating underlying asset code: ${assetCode}</div>
        <div class="pipeline-line dim">&gt;&gt; 🚀 Executing secure SFTP transport package delivery to destination node...</div>
      `
    }
    if (this.hasActionFrameTarget) this.actionFrameTarget.innerHTML = ""
  }

  onPinInput() {
    if (!this.hasPinInputTarget || !this.hasSubmitBtnTarget) return
    this.submitBtnTarget.disabled = this.pinInputTarget.value.length < 4
  }

  onExecute() {
    if (!this.hasPinInputTarget) return
    const pin = this.pinInputTarget.value
    if (pin.length < 4) return

    const data = this._lastClearanceData || {}
    this._transitionToProcessing(data.authorization_id || "—", data.asset_code || "—")
    this.dispatch("mintAuthorized", { detail: { pin, ...data } })
  }

  // Store last clearance payload for execute action
  _transitionToCleared(data) {
    this._lastClearanceData = data
    if (this.hasWrapperTarget) {
      this.wrapperTarget.className = "pipeline-panel pipeline-cleared"
      this.wrapperTarget.classList.add("pipeline-flash")
      setTimeout(() => this.wrapperTarget.classList.remove("pipeline-flash"), 600)
    }
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.innerHTML = `
        <div class="pipeline-line dim">⚡ ISSUANCE DISPATCH PIPELINE</div>
        <div class="pipeline-line dim">──────────────────────────────────────</div>
        <div class="pipeline-line">Status: <span class="ok">🟢 READY TO MINT (Sovereign Authorization Token Verified)</span></div>
        <div class="pipeline-line">Target Allocation: <strong>${data.total_amount} ${data.asset_code} Token Envelope</strong></div>
        <div class="pipeline-line dim">Corridor: ${data.corridor_display}</div>
        <div class="pipeline-line dim">Auth ID: ${data.authorization_id}</div>
      `
    }
    if (this.hasActionFrameTarget) {
      this.actionFrameTarget.innerHTML = `
        <div class="pin-auth-block">
          <label class="pin-label">Enter Secure Spend PIN:</label>
          <div class="pin-row">
            <input type="password" maxlength="4" placeholder="••••"
                   class="pin-input"
                   data-issuance-dispatch-target="pinInput"
                   data-action="input->issuance-dispatch#onPinInput" />
            <button class="btn-mint-execute" disabled
                    data-issuance-dispatch-target="submitBtn"
                    data-action="click->issuance-dispatch#onExecute">
              ⚡ EXECUTE CRYPTOGRAPHIC MINT
            </button>
          </div>
        </div>
      `
    }
  }
}
