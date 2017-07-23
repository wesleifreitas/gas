<cftry>
	<cfset path = getDirectoryFromPath(getCurrentTemplatePath())>
	<cfset restInitApplication(path, "gas")>
	<cfoutput>Success! 'rest-cf-init'</cfoutput>	
	<cfcatch type="any">
		<!--- <cfdump var="#cfcatch#"> --->
	    <cfoutput>Error    'rest-cf-init'
		<cfif IsDefined("cfcatch.Cause.Cause.Detail")>#cfcatch.Cause.Cause.Detail#<cfelseif IsDefined("cfcatch.Cause.Message")>#cfcatch.Cause.Message#</cfif>#cfcatch.detail#</cfoutput>
		<!--- <cfoutput>restInitApplication fault | #cfcatch.message# | #cfcatch.detail#</cfoutput> --->
	    <cfabort>
	</cfcatch>
</cftry>

<!---
<cfhttp 
	url="http://localhost:8500/rest/px-project-a1/example/hello" 
	method="GET" 
	port="8500" 
	result="response">
       <cfhttpparam type="body" value="#SerializeJSON('postExample')#">
</cfhttp>

<cfdump var="#response#">
--->