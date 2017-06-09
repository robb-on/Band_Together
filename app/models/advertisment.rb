class Advertisment < ApplicationRecord

	#association
	belongs_to :user, foreign_key: "user_id"
	belongs_to :band, dependent: :destroy, foreign_key: "band_id"

#SEARCH ENGINE PARAMETER DEFINITIONS

	# Include integration with searchkick
	searchkick word_middle: [:title, :description]

	def search_data
		{
			title: title,
			description: description,
			start_date: start_date,
			term_date: term_date
		}
		
	end

	#validation
	VALID_TITLE_REGEX = /\A[^ ].*\z/ #il titolo non può iniziare con uno spazio
	validates :title, presence: true, length: {maximum: 200}, format: {with: VALID_TITLE_REGEX}, allow_blank: false
	validates :description, presence: true, length: {maximum: 1000}, allow_blank: false
	validates_date :start_date, presence: true
	validates_date :term_date, presence: true,:after => :start_date
		

end
