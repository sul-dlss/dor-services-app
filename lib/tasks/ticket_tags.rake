# frozen_string_literal: true

namespace :ticket_tags do
  desc 'Migrate ticket tags to new format'
  task :migrate, %i[dry_run] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    dry_run = args[:dry_run] != 'false'
    TagLabel.find_each do |original_tag_label|
      original_tag = original_tag_label.tag
      new_tags = TicketTagMigrator.call(tag: original_tag)
      next if new_tags.blank?

      new_tags.each do |tag|
        puts "WARNING: Invalid tag: #{tag}" unless tag.include?(' : ')
      end

      puts "#{original_tag} => #{new_tags.join(', ')}"
      next if dry_run

      druids = original_tag_label.administrative_tags.pluck(:druid)

      ActiveRecord::Base.transaction do
        new_tags.each do |new_tag|
          new_tag_label = TagLabel.find_or_create_by!(tag: new_tag) do |create_tag_label|
            create_tag_label.created_at = original_tag_label.created_at
            create_tag_label.updated_at = original_tag_label.updated_at
          end
          original_tag_label.administrative_tags.find_each do |admin_tag|
            AdministrativeTag.find_or_create_by!(druid: admin_tag.druid, tag_label: new_tag_label) do |create_admin_tag|
              create_admin_tag.created_at = admin_tag.created_at
              create_admin_tag.updated_at = admin_tag.updated_at
            end
          end
        end
        original_tag_label.destroy!
      end
      BatchReindexJob.perform_later(druids)
    end
  end
end
