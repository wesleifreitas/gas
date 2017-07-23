<cfcomponent
    output="false"
    hint="I define the application and root-level event handlers.">

    <!--- Define application settings. --->
    <cfset THIS.Name = "gas" />    
    <cfset THIS.ApplicationTimeout = CreateTimeSpan( 0, 8, 0, 0 ) />
    <cfset THIS.SessionManagement = true />
    <!--- <cfset THIS.SessionTimeout = CreateTimeSpan( 0, 0, 40, 0 ) /> --->
    <cfset THIS.SessionTimeout = CreateTimeSpan( 0, 8, 0, 0 ) />
    <cfset THIS.SetClientCookies = true />
    <cfset THIS.RootDir = getDirectoryFromPath(getCurrentTemplatePath()) />

    <cfparam name="session.loggedIn" default="false" />

    <!--- Define the request settings. --->
    <cfsetting
        showdebugoutput="false"
        requesttimeout="10"
        />

   <cffunction
        name="OnApplicationStart"
        access="public"
        returntype="boolean"
        output="false"
        hint="I run when the application boots up. If I return false, the application initialization will hault.">

        <cfset application.datasource = "gas_sql">

        <cfreturn true />
    </cffunction>


    <cffunction
        name="OnSessionStart"
        access="public"
        returntype="void"
        output="false"
        hint="I run when a session boots up.">
       
        <!--- Return out. --->
        <cfreturn />
    </cffunction>         

    <cffunction
        name="OnRequestStart"
        access="public"
        returntype="boolean"
        output="false"
        hint="I perform pre page processing. If I return false, I hault the rest of the page from processing.">

        <cfargument type="String" name="targetPage" required="true"/>


        
        <!--- Return out. --->
        <cfreturn true />
    </cffunction>

    <cffunction
        name="OnRequest"
        access="public"
        returntype="void"
        output="true"
        hint="I execute the primary template.">

        <!--- Define arguments. --->
        <cfargument
            name="Page"
            type="string"
            required="true"
            hint="The page template requested by the user."
            />


        <cfif SESSION.loggedIn>

            <!--- User logged in. Allow page request. --->
            <cfinclude template="#ARGUMENTS.Page#" />

        <cfelse>

            <cfinclude template="#ARGUMENTS.Page#" />

        </cfif>

        <!--- Return out. --->
        <cfreturn />
    </cffunction>

</cfcomponent>