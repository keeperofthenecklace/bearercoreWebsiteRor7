# lib/capistrano/tasks/audit_readonly.rake
#
# READ-ONLY key-custody audit of the bearerCORE production droplet.
# Prints names, modes, counts and 8-hex SHA-256 fingerprints only — never a
# file's contents, a secret, or an environment variable's value.
#
#   cap production audit:nyc1
require "stringio"
require "securerandom"
require "shellwords"

namespace :audit do
  desc "Read-only: what runs here, where secrets live, any issuer-key material (counts/fingerprints only)"
  task :nyc1 do
    sh = {
      "host"                    => "hostname; uptime -p",
      "app processes"           => "ps -eo user:10,comm,args --no-headers | grep -E 'Passenger (RubyApp|AppPreloader)|sidekiq [0-9]|puma|postgres: |nginx: master' | grep -v grep | awk '{print $1, $3, $4, $5, $6}' | sort | uniq -c",
      "nginx sites"             => "grep -rhE '^\\s*(server_name|root|passenger_app_root|passenger_app_env)\\s' /etc/nginx/sites-enabled/ 2>/dev/null | sed 's/^\\s*//' | sort -u",
      "home dirs"               => "ls -1 $HOME",
      "app dirs"                => "ls -d $HOME/*/current 2>/dev/null; ls -1 $HOME/*/shared/config 2>/dev/null",
      "secret file modes"       => "stat -c '%U:%G %a %n' $HOME/*/shared/config/master.key $HOME/*/shared/config/credentials/*.key $HOME/*/shared/.env $HOME/*/shared/config/database.yml 2>/dev/null",
      ".env variable NAMES"     => "for f in $HOME/*/shared/.env; do echo \"$f: $(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' \"$f\" | tr -d '=' | tr '\\n' ' ')\"; done 2>/dev/null",
      "*.key files under /home" => "find /home -xdev \\( -name 'master.key' -o -name '*.key' \\) -not -path '*/node_modules/*' -not -path '*/.git/*' -printf '%u:%g %m %p\\n' 2>/dev/null | head -20",
      "issuer-key strings in files (names only)" => "grep -rlE 'ISSUER_PRIVATE_KEY_B64URL|private_key_b64url' /home/deploy --exclude-dir={node_modules,.git,vendor,log,public,tmp,assets} 2>/dev/null | head -20",
      "dump-like files"         => "find /home /var/backups /opt -xdev -maxdepth 5 \\( -iname '*.sql' -o -iname '*.sql.gz' -o -iname '*.dump' -o -iname '*.pgdump' \\) -printf '%u:%g %m %s %TY-%Tm-%Td %p\\n' 2>/dev/null | head -20",
      "postgres"                => "systemctl is-active postgresql 2>&1; psql -lqt 2>/dev/null | cut -d'|' -f1 | sed 's/ //g' | grep -v '^$' | tr '\\n' ' '",
      "cron"                    => "crontab -l 2>&1 | grep -v '^#'; ls /etc/cron.d 2>/dev/null | tr '\\n' ' '",
      "disk"                    => "lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null | grep -v loop",
    }
    on roles(:app) do
      sh.each do |label, c|
        out = capture(:bash, "-c", Shellwords.escape(c), raise_on_non_zero_exit: false) rescue "(error)"
        puts "  [nyc1] ── #{label}"
        out.to_s.each_line { |l| puts "  [nyc1]    #{l.chomp}" }
      end
    end

    script = <<~'RB'
      require "digest"
      fp = ->(v) { Digest::SHA256.hexdigest("fp|" + v.to_s)[0, 8] }
      db = ActiveRecord::Base.connection_db_config.configuration_hash rescue {}
      puts "[rb] db adapter=#{db[:adapter]} host=#{db[:host] || 'socket'} database=#{db[:database]}"
      c = ActiveRecord::Base.connection
      puts "[rb] tables_with_key_columns=#{c.tables.select { |t| c.columns(t).any? { |col| col.name =~ /private_key|secret|seed/ } }.map { |t| t + '(' + c.columns(t).map(&:name).grep(/private_key|secret|seed/).join(',') + ')' }.inspect}"
      if c.table_exists?("issuer_keys")
        cols = c.columns("issuer_keys").map(&:name)
        if cols.include?("private_key_b64url")
          raws = c.select_values("SELECT private_key_b64url FROM issuer_keys")
          enc  = raws.count { |r| r.to_s.start_with?('{"p":') }
          puts "[rb] issuer_keys rows=#{raws.size} private_key_present=#{raws.count(&:present?)} ar_encrypted=#{enc} plaintext=#{raws.count(&:present?) - enc}"
        else
          puts "[rb] issuer_keys rows=#{c.select_value('SELECT count(*) FROM issuer_keys')} (no private_key column)"
        end
      else
        puts "[rb] issuer_keys table: absent"
      end
      bt = c.select_values("SELECT tablename FROM pg_tables WHERE tablename LIKE 'issuer_keys_backup_%'") rescue []
      puts "[rb] issuer_keys_backup tables=#{bt.inspect}"
      cr = Rails.application.credentials
      are = cr.active_record_encryption rescue nil
      puts "[rb] credentials secret_key_base_present=#{cr.secret_key_base.present?} active_record_encryption_present=#{are.present?} primary_key_fp=#{are ? Array(are[:primary_key]).map(&fp) : '-'}"
      mk = (File.read(Rails.root.join("config/master.key")).strip rescue nil)
      puts "[rb] master_key_fp=#{mk ? Digest::SHA256.hexdigest('fp|ActiveSupport::KeyGenerator' + mk)[0, 8] : 'n/a'} (smartcheq prod master_key_fp=b06905cf, AR primary fp=3ccf2ae5)"
      puts "[rb] ENV ISSUER_PRIVATE_KEY_B64URL set=#{ENV['ISSUER_PRIVATE_KEY_B64URL'].present?} RAILS_MASTER_KEY set=#{ENV['RAILS_MASTER_KEY'].present?}"
    RB
    on roles(:app) do
      tmp = "/tmp/audit_nyc1_#{SecureRandom.hex(4)}.rb"
      upload! StringIO.new(script), tmp
      out = capture("cd #{current_path} && RAILS_ENV=production $HOME/.rbenv/bin/rbenv exec bundle exec ruby -r./config/environment #{tmp} 2>&1 | grep -aE '^\\[rb\\]' || true")
      execute "rm -f #{tmp}"
      out.each_line { |l| puts "  [nyc1] #{l.chomp}" }
    end
  end
  desc "Read-only: does this droplet reach the SmartCHEQ DB, and could it read issuer-key tables? (host, booleans, counts)"
  task :smartcheq_link do
    script = <<~'RB'
      cfg = SmartcheqRecord.connection_db_config.configuration_hash rescue {}
      puts "[sl] SmartcheqRecord host=#{cfg[:host]} port=#{cfg[:port]} database=#{cfg[:database]} user=#{cfg[:username]} password_from_env=#{ENV['SMARTCHEQ_DB_PASSWORD'].present? || ENV['DB_PASSWORD'].present?}"
      begin
        c = SmartcheqRecord.connection
        puts "[sl] connects=true server_addr=#{c.select_value('SELECT inet_server_addr()')} ssl=#{c.select_value('SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()')}"
        %w[issuer_keys issuer_keys_backup_20261008155101].each do |t|
          n = (c.select_value("SELECT count(*) FROM #{t}") rescue "denied/absent (#{$!.class})")
          puts "[sl] can_select #{t}: rows=#{n}"
        end
      rescue => e
        puts "[sl] connects=false (#{e.class})"
      end
      used = Dir[Rails.root.join("app/**/*.rb").to_s].count { |f| File.read(f).include?("SmartcheqRecord") }
      puts "[sl] app files referencing SmartcheqRecord=#{used}"
    RB
    on roles(:app) do
      tmp = "/tmp/audit_sl_#{SecureRandom.hex(4)}.rb"
      upload! StringIO.new(script), tmp
      out = capture("cd #{current_path} && RAILS_ENV=production $HOME/.rbenv/bin/rbenv exec bundle exec ruby -r./config/environment #{tmp} 2>&1 | grep -aE '^\\[sl\\]' || true")
      execute "rm -f #{tmp}"
      out.each_line { |l| puts "  [nyc1] #{l.chomp}" }
    end
  end

end
