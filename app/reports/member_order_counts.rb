# frozen_string_literal: true

# Generates a report of SDR objects with more than one member order
#
# bin/rails r -e production "MemberOrderCounts.report"
class MemberOrderCounts
  JSON_PATH = 'strict $.hasMemberOrders[*]'
  SQL = <<~SQL.squish.freeze
    SELECT DISTINCT(external_identifier),
      JSONB_ARRAY_LENGTH(
        JSONB_PATH_QUERY_ARRAY(
          structural,
          '#{JSON_PATH}'
        )
      ) AS count
    FROM dros
    WHERE JSONB_ARRAY_LENGTH(
        JSONB_PATH_QUERY_ARRAY(
          structural,
          '#{JSON_PATH}'
        )
      ) > 1
    ORDER BY count DESC
  SQL

  def self.report
    puts 'druid,member_order_count'
    ActiveRecord::Base.connection.execute(SQL).each do |row|
      puts "#{row['external_identifier']},#{row['count']}"
    end
  end
end
