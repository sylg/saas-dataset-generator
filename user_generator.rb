require 'ffaker'
require 'csv'
require 'json'

NUMBER_OF_USERS_TO_GENERATE = ARGV.first
CSV_FILENAME_USER = "users.csv"
CSV_FILENAME_EVENT = "events.csv"


class User
    attr_reader :full_name, :first_name, :last_name, :location, :email, :user_id, :company_domain, :role, :website, :created_at, :events, :type, :last_payment_amount_in_cents
    attr_writer :events, :type, :last_payment_amount_in_cents

    def initialize
        @user_id = FFaker::Guid.guid
        @full_name = FFaker::Name.name
        @first_name = self.full_name.split(" ").first
        @last_name = self.full_name.split(" ").last
        @location = FFaker::Address.country
        @email = FFaker::Internet.disposable_email
        @role = FFaker::Job.title
        @company_domain = FFaker::Internet.domain_name
        @website = FFaker::Internet.http_url
        @created_at = FFaker::Time.between('2019-05-01 16:20', '2020-01-01 16:20')
        @type = "free user"

        generate_associate_events
    end

    def generate_associate_events
        events = []
        # for i in 1..rand(1..50)
        for i in 1..rand(12..120)
            eventName = ["ProductEvent", "MarketingEvent"].sample
            e = Kernel.const_get(eventName).new(self)
            events << e
        end
        @events = events
    end

    def self.generate(amount)
        users =[]
        for i in 1..amount.to_i
            users << User.new
        end
        users
    end
    
end


class Event
    attr_reader :type, :name, :user_id, :created_at, :data

    def initialize(user)
        @type
        @name
        @user_id = user.user_id
        @created_at = FFaker::Time.between(user.created_at, '2020-05-01 16:20')
        @data
    end
end

class ProductEvent < Event
    def initialize(user)
        super(user)
        @type = "product"
        @name = generate_event_name
        @data = generate_event_data
    end

    def generate_event_name
        ["apointment wizard started", "apointment created", "apointment shared", "apointment updated", "apointment deleted"].sample
    end

    def generate_event_data

        {
            apointment_name: FFaker::BaconIpsum.sentence,
            apointment_id: FFaker::Guid.guid,
            apointment_atendee: FFaker::Internet.user_name,
            apointment_date: FFaker::Time.between('2019-05-01 16:20', '2021-05-01 16:20')
        }

    end
end


class MarketingEvent < Event
    def initialize(user)
        super(user)
        @type = "Marketing"
        @name = generate_event_name
        @data = generate_event_data    
    end

    def generate_event_name
        ["page viewed", "button clicked", "email opened", "webinar attended", "content downloaded"].sample
    end

    def generate_event_data

        case self.name
        when "page viewed", "button clicked"
            {
                path: ["/", "/pricing", "/demo", "/customer-stories", "/login", "/blog", "/signup", "/about"].sample,
                browser: ["Safari", "Chrome", "Firefox", "Opera", "Internet Explorer"].sample,
                referrer: FFaker::Internet.http_url
            }
        when "email opened"
            {
                email_title: ["Welcome to our App", "Onboarding Email #1", "Our latest feature is out!", "You are running out of credits", "Here is your receipt"].sample
            }
        when "webinar attended", "content downloaded"
            {
                content_title: ["How to use our app", "The state of our industry 2020", "How to change your role in the company", "The best questions to ask your manager"].sample
            }
        end

    end
end


## THis IS CURRENTLY BROKEN
# class PaymentEvent < Event
#     def initialize(user)
#         super(user)
#         @type = "payment"

#         generate_event_name(user)
        

#     end

#     def generate_event_name(user)
#         p user.type
#         if user.type == "free user"
#             movement = "new"
#         else
#             movement = ["new", "recurring","upgrade","downgrade", "churn"].sample
#         end
        
#         @name = "payment succesful - #{movement}"
        
        
#         generate_payment_data(movement, user)

#     end

#     def generate_payment_data(movement, user)
#         old_amount_in_cents = 0
#         new_amount_in_cents = 0
#         plan_value = [19,49,199,499]

#         if user.type == "free user" && movement == "new"
#             user.type = "customer"
#             old_amount_in_cents = 0
#             new_amount_in_cents = plan_value.sample

#         elsif  user.type == "customer" && movement == "new"
#             return

#         elsif  user.type == "customer" && movement == "churn"
#             user.type = "free user"
#             old_amount_in_cents = user.last_payment_amount_in_cents
#             new_amount_in_cents = 0

#         elsif  user.type == "free user" && movement == "churn"
#             return
#         elsif  user.type == "customer" && movement == "recuring"
#             old_amount_in_cents = user.last_payment_amount_in_cents
#             new_amount_in_cents =user.last_payment_amount_in_cents
            
#         elsif  user.type == "customer" && movement == "upgrade"
#             return if old_amount_in_cents == plan_value.max

#             old_amount_in_cents = user.last_payment_amount_in_cents    
#             new_amount_in_cents = plan_value.find_all {|v| v > old_amount_in_cents}.sample
        
#         elsif user.type == "customer" && movement == "downgrade"
#             return if old_amount_in_cents == plan_value.min

#             old_amount_in_cents = user.last_payment_amount_in_cents    
#             new_amount_in_cents = plan_value.find_all {|v| v < old_amount_in_cents}.sample

#         end

#         user.last_payment_amount_in_cents = new_amount_in_cents


#         @data = {
#             old_amount_in_cents: old_amount_in_cents,
#             new_amount_in_cents: new_amount_in_cents,
#             net_amount_in_cents: old_amount_in_cents-new_amount_in_cents,
#             movement_type: movement
#         }
#     end

# end

def generate_csv
    users = User.generate(NUMBER_OF_USERS_TO_GENERATE)

    events = []
    user_count = 0
    event_count = 0

    CSV.open("./output/#{CSV_FILENAME_USER}", "wb") do |csv|
        csv << users.first.instance_variables.map {|v| v.to_s[1..-1] }[0...-1]
        for user in users
            events << user.events
            csv << user.instance_variables.map  {|value| user.instance_variable_get(value).to_s  }[0...-1]
            user_count += 1
        end
    end


    CSV.open("./output/#{CSV_FILENAME_EVENT}", "wb") do |csv|
        flatten_events = events.flatten
        csv << flatten_events.first.instance_variables.map {|v| v.to_s[1..-1] }

        for event in flatten_events
            csv << event.instance_variables.map do |value|
                if value == :@data
                    event.instance_variable_get(value).to_json    
                else
                    event.instance_variable_get(value).to_s
                end
            end

            csv << event.instance_variables.map  {|value| event.instance_variable_get(value).to_s  }
            event_count += 1
        end
    end
    p "generated files #{CSV_FILENAME_USER} (#{user_count} users) and #{CSV_FILENAME_EVENT} (#{event_count} events)"
end


generate_csv