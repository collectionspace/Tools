begin

    # Starting at the current directory, recursively reads one or more
    # Nuxeo export files. From these, packages up records in an import file
    # that can be read by the CollectionSpace Import service.

    # IMPORTANT:
    # This script does NOT:
    # * Perform any cleanup of records, if that may also be needed.
    # * Generate or insert CSIDs, or macro tags for same.
    # Any work of this type must still be done manually.

    # Requires Ruby 1.8 or later, which includes the REXML library
    require "rexml/document"

    # -------------------------------------
    # Configuration
    # -------------------------------------

    # Name of the service into which records will be imported.
    servicename = "Persons"

    # The record type to be imported.
    recordtype = "Person"

    # An array of one or more schema(s) to be extracted from the
    # export file(s), to be included in records in the import file.
    schemas = [ "persons_common" ]

    # -------------------------------------
    # Defaults
    # -------------------------------------

    # Name of the export file(s) that will be read in,
    # whose data will be used to create the import file.
    export_filename = 'document.xml'

    # Name of the import file to create.  (If the file exists,
    # it will be overwritten each time this script is run.)
    import_filename = 'import.xml'

    # XPath that is expected to match one or more elements
    # in a valid Nuxeo export file
    expected_export_xpath = "/document[@repository]"

    # -------------------------------------

    f = File.open(import_filename, "w+")

    f.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    f.write("<imports>\n")

    recordcount = 0

    Dir.glob("**") do |dir|

        if File.directory?(dir)
        else
            next
        end

        path = dir + '/' + export_filename
        begin
            puts "Reading file " + path
            export_file = File.new( path )
        rescue Exception => e
            puts "[ERROR] Could not read file: " + e.message
            next
        end

        export_doc = REXML::Document.new export_file
        root = export_doc.root

        # Simplistic check that this looks like a Nuxeo export file.
        if (root.elements[expected_export_xpath].nil?)
            puts "[ERROR] File may not be a Nuxeo export file; " +
                "was skipped."
            next
        end

        # Extract the specified schema block(s) from the export file.
        parts = []
        for schema in schemas
            schema_xpath = "schema[@name='" + schema + "']"
            unless root.elements[schema_xpath].nil?
                parts << root.elements[schema_xpath].to_s
            end
        end

        # Create a corresponding record entry in the import file.
        if (parts.length > 0)
            f.write("  <import service=\"" + servicename + "\"")
            f.write(" type=\"" + recordtype + "\">\n")
            # Insert each schema block extracted from the export file
            # into the record entry.
            for part in parts
                f.write("    " + part + "\n")
            end
            f.write("  </import>\n")
            recordcount += 1
        end

    end

    f.write("</imports>\n")
    f.close

    puts "Wrote " + recordcount.to_s + " record(s)" +
        " to import file " + import_filename

end