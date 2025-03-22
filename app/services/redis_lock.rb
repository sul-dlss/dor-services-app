# frozen_string_literal: true

# A simple Redis-based lock implementation.
# This is useful for ensuring that only one worker is processing a given job at a time.
# Based on https://github.com/sul-dlss/preservation_catalog/blob/main/app/jobs/concerns/unique_job.rb
class RedisLock
  # @param [String] key the key to lock
  # @param [Integer] lock_timeout the number of seconds before the lock expires
  # @return [Boolean] true if the lock can be acquired
  def self.lock(key:, lock_timeout:)
    now = Time.now.to_i
    new_expiry_time = now + lock_timeout + 1

    REDIS.with do |conn|
      # return if we successfully acquired the lock
      # "Set key to hold string value if key does not exist" (otherwise no-op) -- https://redis.io/commands/setnx
      if conn.setnx(key, new_expiry_time)
        Rails.logger.info("acquired lock on #{key} (none existed)")
        return true
      end

      # see if the existing lock is still valid and return raise if it is
      # (we cannot acquire the lock during the timeout period)
      key_expires_at = conn.get(key).to_i
      if now <= key_expires_at
        Rails.logger.info("failed to acquire lock on #{key}, because it has not expired (#{now} <= #{key_expires_at})")
        return false
      end

      # otherwise set the new_expiry_time and ensure that no other worker has
      # acquired the lock, possibly pushing out the expiry time further
      # "Atomically sets key to value and returns the old value stored at key." -- https://redis.io/commands/getset
      key_expires_at = conn.getset(key, new_expiry_time).to_i
      if now <= key_expires_at
        Rails.logger.info("failed to acquire lock on #{key} but updated expiry time to #{new_expiry_time} (#{now} <= #{key_expires_at})")
        return false
      end

      Rails.logger.info("acquired lock on #{key} (old lock expired, #{now} > #{key_expires_at})")
      true
    end
  end

  def self.clear_lock(key:)
    Rails.logger.info("clearing lock for #{key}...")
    REDIS.with do |conn|
      conn.del(key).tap do |del_result|
        Rails.logger.info("...cleared lock for #{key} (del_result=#{del_result})")
      end
    end
  end

  # @param [String] key the key to lock
  # @param [Integer] lock_timeout the number of seconds before the lock expires
  # @return [Boolean] true if the lock can be acquired
  def self.with_lock(key:, lock_timeout:)
    return false unless lock(key: key, lock_timeout:)

    begin
      yield
    ensure
      clear_lock(key: key)
    end
    true
  end
end
