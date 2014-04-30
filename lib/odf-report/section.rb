module ODFReport

  class Section
    include Fields, Nested, Images

    attr_accessor :fields, :tables, :data, :name, :collection_field, :parent, :images, :image_names_replacements

    def initialize(opts)
      @name             = opts[:name]
      @collection_field = opts[:collection_field]
      @collection       = opts[:collection]
      @parent           = opts[:parent]

      @fields = []
      @texts = []

      @tables = []
      @sections = []
      @images = {}
      @image_names_replacements = {}
    end

    def add_field(name, data_field=nil, &block)
      opts = {:name => name, :data_field => data_field}
      field = Field.new(opts, &block)
      @fields << field

    end

    def add_text(name, data_field=nil, &block)
      opts = {:name => name, :data_field => data_field}
      field = Text.new(opts, &block)
      @texts << field

    end

    def add_table(table_name, collection_field, opts={}, &block)
      opts.merge!(:name => table_name, :collection_field => collection_field, :parent => self)
      tab = Table.new(opts)
      @tables << tab

      yield(tab)
    end

    def add_section(section_name, collection_field, opts={}, &block)
      opts.merge!(:name => section_name, :collection_field => collection_field, :parent => self)
      sec = Section.new(opts)
      @sections << sec

      yield(sec)
    end

    def add_image(name, path=nil, &block)
      @images[name] = path || block
    end

    def populate!(row)
      @collection = get_collection_from_item(row, @collection_field) if row
    end

    def replace!(doc, row = nil, parent = nil)

      return unless section = find_section_node(doc)

      template = section.dup

      populate!(row)

      @collection.each do |data_item|
        new_section = template.dup

        @texts.each do |t|
          t.replace!(new_section, data_item)
        end

        @tables.each do |t|
          t.replace!(new_section, data_item)
        end

        find_image_name_matches(new_section)

        @sections.each do |s|
          s.replace!(new_section, data_item, s)
        end

        replace_fields!(new_section, data_item)

        section.before(new_section)

        @images.each do |k, v|
          if v.instance_of?(Proc)
            image_path = v.call(data_item)
            if node = new_section.xpath(".//draw:frame[@draw:name='#{k}']/draw:image").first
              node.set_attribute('xlink:href', image_path)
            end
          end
        end
      end

      section.remove

    end # replace_section

  private

    def find_section_node(doc)

      sections = doc.xpath(".//text:section[@text:name='#{@name}']")

      sections.empty? ? nil : sections.first

    end

  end

end
