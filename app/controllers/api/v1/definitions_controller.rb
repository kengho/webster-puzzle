class Api::V1::DefinitionsController < Api::V1::BaseController
  def index
    unless params[:word] || params[:words]
      throw_error('external', 'Expected word or words[] as param.') and return
    end

    word = params[:word]
    words = params[:words]

    if word
      record = Record.find_by(word: word)
      linked_definitions = record ? record.linked_definitions : []
    elsif words
      linked_definitions = {}
      words.each do |current_word|
        record = Record.find_by(word: current_word)
        linked_definitions[current_word] =
          record ? record.linked_definitions : []
      end
    end

    response = { data: { definitions: linked_definitions } }

    render json: response
  end
end
