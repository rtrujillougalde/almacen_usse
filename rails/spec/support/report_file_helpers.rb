require "zip"
require "nokogiri"
require "stringio"

module ReportFileHelpers
  module_function

  def pdf_text(binary)
    PDF::Reader.new(StringIO.new(binary)).pages.map(&:text).join("\n")
  end

  # Returns [headers, *data_rows] as arrays of strings from the first worksheet.
  def xlsx_rows(binary)
    rows = nil
    with_xlsx(binary) do |zip|
      shared = parse_shared_strings(zip)
      sheet_entry = zip.glob("xl/worksheets/sheet*.xml").min_by(&:name)
      raise "No worksheet found in XLSX" unless sheet_entry

      doc = Nokogiri::XML(read_zip_entry(sheet_entry))
      doc.remove_namespaces!

      rows = doc.xpath("//sheetData/row").map do |row|
        row.xpath("c").map { |cell| cell_value(cell, shared) }
      end
    end
    rows
  end

  def xlsx_sheet_names(binary)
    names = nil
    with_xlsx(binary) do |zip|
      workbook = Nokogiri::XML(read_zip_bytes(zip, "xl/workbook.xml"))
      workbook.remove_namespaces!
      names = workbook.xpath("//sheets/sheet").map { |node| node["name"] }
    end
    names
  end

  def with_xlsx(binary)
    Zip::File.open_buffer(StringIO.new(binary)) do |zip|
      yield zip
    end
  end

  def read_zip_bytes(zip, path)
    entry = zip.find_entry(path) || raise("Missing #{path} in XLSX")
    read_zip_entry(entry)
  end

  def read_zip_entry(entry)
    data = entry.get_input_stream.read
    data.respond_to?(:force_encoding) ? data.force_encoding("UTF-8") : data
  end

  def parse_shared_strings(zip)
    entry = zip.find_entry("xl/sharedStrings.xml")
    return [] unless entry

    doc = Nokogiri::XML(read_zip_entry(entry))
    doc.remove_namespaces!
    doc.xpath("//si").map { |si| si.xpath(".//t").map(&:text).join }
  end

  def cell_value(cell, shared)
    type = cell["t"]

    case type
    when "inlineStr"
      return cell.xpath(".//t").map(&:text).join
    when "s"
      raw = cell.at_xpath("v")&.text
      return "" unless raw

      return shared[raw.to_i].to_s
    end

    value_node = cell.at_xpath("v")
    value_node ? value_node.text : ""
  end
end

RSpec.configure do |config|
  config.include ReportFileHelpers
end
