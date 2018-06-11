1. Download the CollectionSpace "Tools" git repository from GitHub
   * git clone https://github.com/collectionspace/Tools.git
2. In the new "Tools" directory, edit the "create-report-records.sh" file to add the Public Art tenant.  Use the tenant short name -e.g., "publicart"
    * Open the file
        ```
        vim scripts/create-report-records.sh
        ```
    * Near (or on) line 20, replace the string
        ```
        TENANTS+=(core)
            with the string
	    TENANTS+=(publicart)
        ```
    * Near (or on) line 85, set the default admin user's password.
    * Near the same line, set the HOST and PORT values of the CollectionSpace server
    * Save your changes and quit the editor.
3. If it is not already running, start the CollectionSpace server.
4. Verify you can login and access the CollectionSpace server using the default admin credentials.
5. From the top-level "Tools" directory, run the following commands:
    ```
    chmod u+x ./scripts/*.sh
    ./scripts/install_report_records.sh
    ```
