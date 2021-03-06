class Band < ApplicationRecord
	 before_destroy :destroy_conversations

	include ActiveModel::Validations

	#association
	belongs_to :band_manager, class_name: "User"

	has_many :advertisment,  foreign_key: 'band_id', dependent: :destroy

	has_many :band_conversations, :foreign_key => "band_id", dependent: :destroy
	has_many :conversations, class_name: "Mailboxer::Conversation",  through: :band_conversations #, dependent: :destroy

	#andrea association for band member
	has_many :member_associations,  foreign_key: :joined_band_id, inverse_of: :joined_band, dependent: :destroy
	has_many :users,  through: :member_associations

	has_many :reviews, as: :reviewable, dependent: :destroy

	has_many :following_relationships, as: :followable, dependent: :destroy
	has_many :followers, through: :following_relationships

	has_many :join_requests, foreign_key: "band_id", source: :band, dependent: :destroy

	has_many :activities,  dependent: :destroy

	has_many :passive_notification,  -> {where :notifiable_type => "Band"}, class_name: 'Notification', foreign_key: "notifiable_id", dependent: :destroy

	has_many :active_user_action, -> {where :sender_type => "Band"}, class_name: "UserAction", foreign_key: "sender_id", dependent: :destroy
	has_many :passive_user_action, -> {where :receiver_type => "Band"}, class_name: "UserAction", foreign_key: "receiver_id", dependent: :destroy

	#SEARCH ENGINE PARAMETER DEFINITIONS

	# Include integration with searchkick
	searchkick word_start: [:name, :band_nation, :band_region, :band_city, :band_manager, :musical_genre_name], text_middle: [:description]

	def search_data
		{
			name: name,
			band_nation: nation,
			band_region: region,
			band_city: city,
			description: description,
			band_manager: band_manager.username,
			band_manager_id: band_manager.id,
			musical_genre_name: MusicalGenre.find_by_id(musical_genre_id).name,
			band_genre_id: musical_genre_id
		}
	end

	def active_users
		@actives = []

		@actives << band_manager

		users.each do |usr|
			@actives << usr
		end

		

		@actives
	end







	def users_to_notify
		@res = []

		users.each do |usr|
			@res << usr
		end

		@res << band_manager

		self.followers.each do |usr|
			if !@res.include?(usr)
				@res << usr
			end
		end
		return @res
	end


	def self.active_bands_for(user)
		@bands = []
		Band.where(band_manager:user).each do |b|
			@bands << b
		end
		user.joined_bands.each do |b|
			@bands << b
		end
		@bands
	end


	def reviews_average

    	return self.reviews.average('rating').to_f
  	end


  	def pending_invitation(user)
  		
  		self.pending_join_requests_invitation.where(:receiver_id => user.id)
  	end

	def pending_join_requests_request

  		self.join_requests.where(:pending => true, :req_type => "request")
  	end  	

  	def pending_join_requests_invitation

  		self.join_requests.where(:pending => true, :req_type => "invitation")
  	end

	class  GenreValidator < ActiveModel::EachValidator

    	def validate_each(record, attribute, value)
      		record.errors.add attribute, "Not a supported musical genre" unless ["Rock", "Metal", "Jazz", "Blues", "Pop", "Classic", "Latin", ""].include? MusicalGenre.find(value).name
    	end
  	end


	#Nation validation

	class  NationValidator < ActiveModel::EachValidator

		def validate_each(record, attribute, value)
			 record.errors.add attribute, "Not a valid Nation" unless CS.countries.has_value? value
		end
	end


	#Region validation

	class  RegionValidator < ActiveModel::EachValidator

		def validate_each(record, attribute, value)
		 record.errors.add attribute, "Not a valid Region" unless CS.states(CS.countries.key(record.nation)).has_value? value
		end
	end

	class  CityValidator < ActiveModel::EachValidator
		def validate_each(record, attribute, value)
			nationKey = CS.countries.key(record.nation)
			regionKey = CS.states(nationKey).key(record.region)
			record.errors.add attribute, "Not a valid City" unless CS.get( nationKey ,regionKey ).include? value
		end
	end


	class UserValidator < ActiveModel::EachValidator
		def validate_each(record, attribute, value)
			record.errors.add attribute, "It's not a valid user" unless !User.find_by_id(value).nil?
		end
	end

	#Validations
	VALID_NAME_REGEX = /\A[^ ].*\z/ #il nome non può iniziare con uno spazio
	validates :name, presence: true, length: {maximum: 100}, format: {with: VALID_NAME_REGEX}
	validates :description, presence: true, length: {maximum: 1000}, allow_blank: false
	validates :nation, allow_blank: false, length: {maximum: 50}, nation: true, allow_nil: true
	validates :region, allow_blank: false, length: {maximum: 50}, allow_nil: true, region: true
  	validates :city, allow_blank: false, length: {maximum: 50}, allow_nil: true, city: true
	validates :band_manager_id, presence: true, allow_nil: false, user: true
	validates :musical_genre_id, length: {maximum: 50}, presence: true, allow_nil: false, genre: true



	private

	def destroy_conversations
     self.conversations.each(&:destroy)
   end
end
