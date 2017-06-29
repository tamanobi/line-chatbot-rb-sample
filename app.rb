require 'sinatra'
require 'line/bot'

get '/' do
    # list users up and display
    'hello'
end

get '/list/friends' do
    File.open("friend.txt", "r") do |f|
        f.each_line { |line|
            puts line
        }
    end
end

get '/test/push' do
    userId = ENV["LINE_TEST_USER_ID"]
    message = {
        type: 'text',
        text: 'push message'
    }
    response = client.push_message(userId, message)
    p "#{response.code} #{response.body}"
end

get '/test/profile' do
    userId = ENV["LINE_TEST_USER_ID"]
    response = client.get_profile(userId)
    case response
    when Net::HTTPSuccess then
        contact = JSON.parse(response.body)
        p contact['displayName']
        p contact['pictureUrl']
        p contact['statusMessage']
    else
        p "#{response.code} #{response.body}"
    end
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  unless client.validate_signature(body, request.env['HTTP_X_LINE_SIGNATURE'])
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        response = event.message['text']
        case response
        when response = 'なんかつかれちゃった'
          message = {
            type: 'template',
            altText: 'May I help you',
            template: {
                type: 'confirm',
                text: 'なにかできるかな？',
                actions: [
                  {
                    type: 'message',
                    label: 'Yes',
                    text:  'うん。'
                  },
                  {
                    type: 'message',
                    label: 'No',
                    text:  'やっぱりいいや'                      
                  }
                ]
              }
            }
        client.reply_message(event['replyToken'], message)          
        when response = 'うん'
          message = {
            type: 'text',
            text: 'お話きくよ'
            }
        client.reply_message(event['replyToken'], message)
        when response = '最近前髪が変っていわれるんだ'
          message = {
            type: 'text',
            text: 'ううん！そんなことないよ！'
            }
        client.reply_message(event['replyToken'], message)
        when response = '本当かな？'
          message = {
            type: 'text',
            text: '本当だよ！'
            }
        client.reply_message(event['replyToken'], message)            
        when response = 'そっかありがとうね'
          message = {
            type: 'text',
            text: 'いつでも話しかけね！'
            }
        client.reply_message(event['replyToken'], message)
        when response = 'やっぱりいいや'
          message = {
            type: 'text',
            text: 'いつでも聞くよ！またね！'
            }
        client.reply_message(event['replyToken'], message)              when response = 'スニーカーが欲しいな'
          message = {
            type: 'template',
            altText: 'this is a buttons template',
            template: {
                type: 'buttons',
                thumbnailImageUrl: 'https://github.com/tomitomi0830/line-chatbot-rb-sample/blob/master/img1.jpg',
                title: 'Menu',
                text: 'Please select',
                actions: [
                  {
                    type: 'message',
                    label: '購入する',
                    text:  '購入する'
                  },
                  {
                    type: 'message',
                    label: '購入しない',
                    text:  '購入しない'                      
                  }
                ]
              }
            }
        client.reply_message(event['replyToken'], message)    
        else
            message = {
                type: 'text',
                text: 'は？'
            }
        client.reply_message(event['replyToken'], message)      
        end
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    when Line::Bot::Event::Follow
        message = [{
          type: 'text',
          text: '追加してくれてありがと！'
        },
        {
          type: 'text',
          text: event['source']['userId']
        }]
        File.open("friend.txt", "a") do |f|
            f.puts event['source']['userId']+"\n"
        end
        client.reply_message(event['replyToken'], message)
    end
  }

  "OK"
end
