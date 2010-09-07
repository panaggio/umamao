# Ad hoc Array pagination

class Array

  # Paginates an Array, defining methods as expected by
  # will_paginate. Accepts two options, which work as in the regular
  # paginate method: :per_page and :page
  def paginate(options = {})
    default_options = {:per_page => 25, :page => 1}
    options = default_options.merge(options)

    total = (self.count + options[:per_page].to_i - 1) / options[:per_page].to_i
    current = options[:page].to_i
    current = 1 if current < 1
    current = total if current > total
    previous =  current > 1 ? current - 1 : nil
    nx = current < total ? current + 1 : nil
    first = (current - 1) * options[:per_page]

    paginated_array = self[first ... first + options[:per_page]]
    paginated_array.do_paginate(total, current, previous, nx, self.count)
    paginated_array
  end


  protected

  # Augments the methods accepted by the paginated result in order to
  # work with will_paginate
  def do_paginate(pages, current, previous, nx, total_entries)
    @pages = pages
    @current = current
    @previous = previous
    @nx = nx
    @total_entries = total_entries
    
    def self.total_pages
      @pages
    end
    
    def self.current_page
      @current
    end

    def self.previous_page
      @previous
    end

    def self.next_page
      @nx
    end

    def self.total
      @total_entries
    end
  end

end
