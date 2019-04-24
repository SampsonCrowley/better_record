# encoding: utf-8
# frozen_string_literal: true

module BetterRecord
  class FakeRedis
    def data
      @data ||= {}
    end

    def incr(key)
      data[key] ||= 0
      data[key] += 1
    end

    def decr(key)
      data[key] ||= 0
      data[key] -= 1
    end

    def set(key, val)
      data[key] = val
    end

    def get(key)
      data[key].dup
    end

    def lpush(key, val)
      require_array
      data[key].unshift val
      data[key].size
    end

    def lrem(key, count, val)
      require_array
      start_idx = 0
      arr = data[key]
      removed = 0

      if count == 0
        removed = (arr.select {|v| v != val}).size
        arr.select! {|v| v != val}
      else
        arr.reverse! if count < 0

        count.abs.times do
          removed += 1 unless arr.delete_at(arr.index(val) || arr.size).nil?
        end

        arr.reverse! if count < 0
      end

      data[key] = arr
      removed
    end

    def lrange(key, start_idx, end_idx = -1)
      data[key][start_idx..end_idx] || []
    end

    def rpush(key, val)
      require_array
      data[key] << val
      data[key].size
    end

    def rpushx(key, val)
      return 0 unless data[key]
      rpush key, val
    end

    def rpop(key)
      require_array
      data[key].pop
    end

    def rpoplpush(one, two)
      val = rpop(one)
      lpush two, val
      val
    end

    def keys(pattern = ".*")
      data.keys.filter {|k| k.to_s =~ /^#{pattern}$/}
    end

    def del(*keys)
      i = 0
      keys.map {|k| data.delete(k) && (i += 1) }
      i
    end

    def method_missing
      return nil
    end

    private
      def require_array(key)
        data[key] ||= []
        raise_wrong_type unless data[key].is_a?(Array)
      end

      def raise_wrong_type
        raise CommandError.new("WRONGTYPE Operation against a key holding the wrong kind of value")
      end
  end
end
