require 'nokogiri'

module LiveSplit
  class << self
    def shortname
      'livesplit'
    end

    def file_extension
      'lss'
    end

    def read!(run_file)
      xml = Nokogiri::XML(run_file.file)

      ActiveRecord::Base.transaction do
        if run[:segments].count > run_file.segments.count
          (run[:segments].count - run_file.segments.count).times { run_file.segments.new }
        elsif run[:segments].count < run_file.segments.count
          run_file.segments.limit(run_file.segments.count - run[:segments].count).destroy_all
        end

        real_duration, game_duration = 0, 0

        xml.css('Run > Segments > Segment').map.with_index do |segment, index|
          run_file.segments[index].update(
            order: index,
            name: segment.at('Name').content,
            real_duration: real_duration += ChronicDuration.parse(
              segment.at('SplitTimes > SplitTime[name="Personal Best"] > RealTime').content
            ),
            game_duration: game_duration += ChronicDuration.parse(
              segment.at('SplitTimes > SplitTime[name="Personal Best"] > GameTime').content
            ),
            best_real_duration: segment.at('BestSegmentTime RealTime').content,
            best_game_duration: segment.at('BestSegmentTime GameTime').content
          )
        end.all? && run_file.runs.update_all(
          program: :livesplit,
          time: run_file.segments.sum(:real_duration),
          name: "#{xml.at('Run > GameName').content} #{xml.at('Run > CategoryName').content}",
          category_id: Game.from_name(xml.at('Run > GameName').content).try do |game|
            game.categories.from_name(xml.at('Run > CategoryName').content)
          end
        )
      end
    end
  end
end