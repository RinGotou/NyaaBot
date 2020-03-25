# -*- coding: UTF-8 -*-
require 'telegram/bot'
require 'toml-rb'

# Fix: chdir()
# require './utility/trending.rb'

module UserMode
    STANDARD = 0
    COUNTING = 1
end

# constants
$DEFAULT_CONFIG_FILE = './nyaabot_config.toml'
$USER_INFO_FILE      = './nyaabot_users.toml'
$PROXY_KEY           = 'proxy_url'
$TOKEN_KEY           = 'token'
$HELP_MSG            = <<-HELP_MSG
/nyaa:    喵x1
/sqeeze:  撸猫
/manzoku: 给猫摆放一条一本满足棒
/count:   让猫进入复读机模式(不断叠加'喵')

以下是尚未实现的指令:
/trending_cxx:  获取当前Github Trending(C++)
/trending_ruby: 获取当前Github Trending(Ruby)
HELP_MSG

$STATIC_RESPONSE = {
    '/start'         => '吾輩は猫である. 名前はまだ無い. ',
    '/nyaa'          => '喵',
    '/sqeeze'        => '(类似于打雷的呼噜声)',
    '/help'          => $HELP_MSG,
    '/manzoku'       => 'https://www.nicovideo.jp/watch/sm13180865',
    :none            => '这我也不太清楚, 因为我只是一只猫...',
    :end_of_counting => '(盯......)'
}

$user_mode = {}

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

def build_nyaa_string(count)
    result = ''
    count.times { |index| result << '喵' }
    result << '?'
    result
end

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

    if !$user_mode.has_key? message.chat.id
        generate_msg("Create user info for #{message.chat.id}")
        appendable_hash = { message.chat.id => {
                mode:     UserMode::STANDARD,
                count:    0
            }
        }
        $user_mode.merge! appendable_hash
    end

    if $user_mode[message.chat.id][:mode] == UserMode::COUNTING
        generate_msg("Count of #{message.chat.id}: #{$user_mode[message.chat.id][:count]}")
        if message.text == '喵'
            $user_mode[message.chat.id][:mode] = UserMode::STANDARD
            $user_mode[message.chat.id][:count] = 0
            bot.api.send_message chat_id: message.chat.id, text: $STATIC_RESPONSE[:end_of_counting]
        else
            count = $user_mode[message.chat.id][:count]
            bot.api.send_message chat_id: message.chat.id, text: build_nyaa_string(count)
            count = count + 1
            $user_mode[message.chat.id][:count] = count
        end
    else
        case message.text
        when '/start', '/nyaa', '/help', '/sqeeze', '/manzoku'
            bot.api.send_message chat_id: message.chat.id, text: $STATIC_RESPONSE[message.text]
        when '/count'
            $user_mode[message.chat.id][:mode] = UserMode::COUNTING
        else
            bot.api.send_message chat_id: message.chat.id, text: $STATIC_RESPONSE[:none]
        end
    end
end

main_botloop()
