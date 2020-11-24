require "rails_helper"
require 'dotenv/load'
require 'faker'
require 'securerandom'

class VCR
  def self.load(file_path)
    path = Rails.root.join('spec', 'fixtures', file_path + '.json')
    # puts path
    if File.exist?(path)
      return File.read(path)
    end
  end
end

RSpec.describe Vonage do

  before(:each) do
    @vonage = Vonage.new()
  end

  describe 'balance' do
    it " - retrieves balance" do
      value = rand(1.5..3000.0)
      allow(@vonage.data_source).to receive(:balance).and_return('{"value":' + value.to_s + ',"autoReload":false}')
      balance = @vonage.balance
      expect(balance).to eq(value)
    end
    it " - error balance - invalid response" do
      allow(@vonage.data_source).to receive(:balance).and_return(nil)
      balance = @vonage.balance
      expect(balance).to eq(0)
    end
    it " - error balance - no value property" do
      allow(@vonage.data_source).to receive(:balance).and_return('{"autoReload":false}')
      balance = @vonage.balance
      expect(balance).to eq(0)
    end
    it " - error balance - no value property" do
      allow(@vonage.data_source).to receive(:balance).and_return('{"value":"abc","autoReload":false}')
      balance = @vonage.balance
      expect(balance).to eq(0)
    end
  end

  describe "apps - retrieve" do
    it " - retrieves apps" do
      allow(@vonage.data_source).to receive(:apps).and_return(VCR.load('apps/success'))
      apps = @vonage.apps
      expect(apps).to_not be_nil
      expect(apps.first.id).to eq("032544e0-8a62-495e-b960-351e6188ae11")
    end
    it " - error balance - invalid response" do
      allow(@vonage.data_source).to receive(:apps).and_return(nil)
      apps = @vonage.apps
      expect(apps).to eq([])
    end
    it " - error balance - empty response" do
      allow(@vonage.data_source).to receive(:apps).and_return("")
      apps = @vonage.apps
      expect(apps).to eq([])
    end
    it " - error balance - empty response" do
      allow(@vonage.data_source).to receive(:apps).and_return("{}")
      apps = @vonage.apps
      expect(apps).to eq([])
    end
    it " - error balance - invalid response" do
      allow(@vonage.data_source).to receive(:apps).and_return('{ "_embedded": "test"}')
      apps = @vonage.apps
      expect(apps).to eq([])
    end
    it " - error balance - invalid response" do
      allow(@vonage.data_source).to receive(:apps).and_return('{ "_embedded": {"application": "test"}}')
      apps = @vonage.apps
      expect(apps).to eq([])
    end
  end



  # it " - create an app" do
  #   new_app_properties = {
  #     name: Faker::App.name, 
  #     public_key: '???',
  #     voice_answer_method: 'GET', voice_answer_url: Faker::Internet.url,
  #     voice_event_method: 'POST', voice_event_url: Faker::Internet.url,
  #     rtc_event_method: 'POST', rtc_event_url: Faker::Internet.url
  #   }

  #   apps = Vonage.apps(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   expect(apps).to_not be_nil
  #   before_count = apps.count

  #   new_app = Vonage.app_create(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'], new_app_properties)
  #   expect(new_app).to be_truthy
  #   puts new_app.inspect

  #   after_apps = Vonage.apps(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   expect(after_apps).to_not be_nil
  #   expect(after_apps.count).to eq(before_count + 1)
  # end


  # it " - retrieves numbers" do
  #   numbers = Vonage.numbers(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   # puts numbers.inspect
  #   expect(numbers).to_not be_nil
  # end

  # it " - search numbers" do
  #   numbers = Vonage.number_search(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'],'US')
  #   # puts numbers.inspect
  #   expect(numbers).to_not be_nil
  # end

  # it " - buy number" do
  #   before_numbers = Vonage.numbers(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   # puts numbers.inspect
  #   expect(before_numbers).to_not be_nil
  #   before_count = before_numbers.count

  #   country = 'US'
  #   search_numbers = Vonage.number_search(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'], country)
  #   expect(search_numbers).to_not be_nil
  #   msisdn = search_numbers.first["msisdn"]
  #   expect(msisdn).to_not be_nil
  #   expect(Vonage.number_buy(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'], country, msisdn)).to be_truthy

  #   after_numbers = Vonage.numbers(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   # puts numbers.inspect
  #   expect(after_numbers).to_not be_nil
  #   expect(after_numbers.count).to eq(before_count + 1)
  # end

  # it " - links / unlinks number to app" do
  #   apps = Vonage.apps(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   expect(apps).to_not be_nil
  #   expect(apps.count).to be > 0
  #   app = apps.first
  #   numbers = Vonage.numbers(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   expect(numbers).to_not be_nil
  #   expect(numbers.count).to be > 0
  #   number = numbers.first

  #   expect(Vonage.number_link(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'], number.country, number.msisdn, nil)).to be_truthy
  #   numbers = Vonage.numbers(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   number = numbers.first
  #   puts number.inspect
  #   expect(number.voiceCallbackType).to be_nil
  #   expect(number.voiceCallbackValue).to be_nil

  #   expect(Vonage.number_link(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'], number.country, number.msisdn, app.id)).to be_truthy
  #   numbers = Vonage.numbers(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   number = numbers.first
  #   puts number.inspect
  #   expect(number.voiceCallbackType).to eq('app')
  #   expect(number.voiceCallbackValue).to eq(app.id)
    
  #   expect(Vonage.number_link(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'], number.country, number.msisdn, nil)).to be_truthy
  #   numbers = Vonage.numbers(ENV['VONAGE_API_KEY'], ENV['VONAGE_API_SECRET'])
  #   number = numbers.first
  #   puts number.inspect
  #   expect(number.voiceCallbackType).to be_nil
  #   expect(number.voiceCallbackValue).to be_nil

  # end


  it " - generates admin jwt" do
    jwt = @vonage.admin_jwt
    expect(jwt).to_not be_nil
  end
  

  it " - retrieve users" do
    users = Vonage.users(ENV['APP_ID'], ENV['APP_PRIVATE_KEY'])
    expect(users).to_not be_nil
    expect(users._embedded.users).to_not be_nil
    expect(users._links).to_not be_nil
  end

  
  # it " - create a user" do
  #   name = Faker::Name.first_name + "-" + SecureRandom.uuid
  #   display_name = Faker::Name.name
  #   user = Vonage.create_user(ENV['APP_ID'], ENV['APP_PRIVATE_KEY'], name, display_name)
  #   puts user.inspect
  #   expect(user).to_not be_nil
  #   expect(user.id).to_not be_nil
  #   expect(user._links.self).to_not be_nil
  # end

  # it " - delete a user" do
  #   users = Vonage.users(ENV['APP_ID'], ENV['APP_PRIVATE_KEY'])
  #   before_count = users._embedded.users.count
  #   expect(users._embedded.users.count).to be > 0
  #   user_id = users._embedded.users.first.id
  #   expect(user_id).to_not be_nil
  #   expect(Vonage.delete_user(ENV['APP_ID'], ENV['APP_PRIVATE_KEY'], user_id)).to be_truthy
  #   users = Vonage.users(ENV['APP_ID'], ENV['APP_PRIVATE_KEY'])
  #   expect(users._embedded.users.count).to eq(before_count - 1)
  # end

end