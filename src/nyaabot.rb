# -*- coding: UTF-8 -*-

require 'telegram/bot'
require 'toml-rb'
require 'nokogiri'
require 'net/http'
# require 'accuweather'

# constants
$DEFAULT_CONFIG_FILE = './nyaabot_config.toml'
$USER_INFO_FILE      = './nyaabot_users.toml'
$PROXY_KEY           = 'proxy_url'
$TOKEN_KEY           = 'token'

# variables
$bot = nil

$STATIC_RESPONSE = {
    '/start'  => '吾輩は猫である. 名前はまだ無い. ',
    '/nyaa'   => '喵',
    '/sqeeze' => '(类似于打雷的呼噜声)',
    # reserved for further completion
    '/help'  => '',
    :none    => '这我也不太清楚, 因为我只是一只猫...'
}

def generate_msg(str)
    puts "[#{Time.now.to_s}] #{str}"
end

def generate_error_msg(str, exception)
    generate_msg(str)
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
            generate_msg('Listen to messages...')
            bot.listen { |message| yield message, bot }
        end
    else
        Telegram::Bot::Client.run(config[:token]) do |bot|
            generate_msg('Listen to messages...')
            bot.listen { |message| yield message, bot }
        end
    end
end

main_botloop do |message, bot|
    generate_msg("Receive message from #{message.chat.id}")
    case message.text
    when '/start', '/nyaa', '/help'
        bot.api.send_message chat_id: message.chat.id, text:$STATIC_RESPONSE[message.text]
    else
        bot.api.send_message chat_id: message.chat.id, text:$STATIC_RESPONSE[:none]
    end
end

main_botloop()
