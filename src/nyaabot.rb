require 'telegram/bot'
require 'toml-rb'
require 'nokogiri'
require 'net/http'

# constants
$DEFAULT_CONFIG_FILE = './nyaabot_config.toml'
$PROXY_KEY           = 'proxy_url'
$TOKEN_KEY           = 'token'

# variables
$bot = nil

def generate_error_msg(str, exception)
    puts str
    puts "Details :(#{exception.class.to_s}) #{exception.message}"
end

def fetch_configuration
    proxy_url_value = nil
    token_value     = nil

    begin
        config_file = TomlRB.parse(File.open($DEFAULT_CONFIG_FILE))
        token_value = config_file[$TOKEN_KEY]
        if config_file.has_key? $PROXY_KEY
            proxy_url_value = config_file[$PROXY_KEY]
        end

    rescue RuntimeError => exception
        generate_error_msg('Failed to open config file', exception)
        return nil
    rescue ParseError   => exception
        generate_error_msg('Invalid content of config file', exception)
        return nil
    end

    { proxy_url:proxy_url_value, token:token_value }
end

# todo: bot feature functions
# ...

# main processing
def main_botloop
    config = fetch_configuration

    if config == nil; return; end
    if config[:proxy_url] != nil
        Telegram::Bot::Client.run(config[:token], url:config[:proxy_url]) do |bot|
            puts 'Listen to messages...'
            bot.listen { |message| yield message, bot }
        end
    else
        Telegram::Bot::Client.run(config[:token]) do |bot|
            puts 'Listen to messages...'
            bot.listen { |message| yield message, bot }
        end
    end
end

main_botloop do |message, bot|
    case message.text
    when '/nyaa'
        bot.api.send_message chat_id: message.chat.id, test:'Nyaa~~~~'
    else
        bot.api.send_message chat_id: message.chat.id, text:'I don\'t know your request~~~~'
    end
end

main_botloop()
