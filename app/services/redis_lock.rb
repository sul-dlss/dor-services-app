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
      return true if conn.setnx(key, new_expiry_time)

      # see if the existing lock is still valid and return raise if it is
      # (we cannot acquire the lock during the timeout period)
      key_expires_at = conn.get(key).to_i
      return false if now <= key_expires_at

      # otherwise set the new_expiry_time and ensure that no other worker has
      # acquired the lock, possibly pushing out the expiry time further
      # "Atomically sets key to value and returns the old value stored at key." -- https://redis.io/commands/getset
      key_expires_at = conn.getset(key, new_expiry_time).to_i
      return false if now <= key_expires_at

      true
    end
  end

  def self.clear_lock(key:)
    Rails.logger.info("clearing lock for #{key}...")
    REDIS.with do |conn|
      conn.del(key)
    end
  end

  # @param [String] key the key to lock
  # @param [Integer] lock_timeout the number of seconds before the lock expires
  # @return [Boolean] true if the lock can be acquired
  def self.with_lock(key:, lock_timeout:) # rubocop:disable Naming/PredicateMethod
    return false unless lock(key: key, lock_timeout:)

    begin
      yield
    ensure
      clear_lock(key: key)
    end
    true
  end
end
