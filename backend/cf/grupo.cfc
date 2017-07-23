<cfcomponent rest="true" restPath="grupo">  
	<cfinclude template="security.cfm">
	<cfinclude template="util.cfm">

	<cffunction name="grupo" access="remote" returntype="String" httpmethod="GET"> 

		<cfset checkAuthentication()>
        
		<cfset response = structNew()>
		
		<cfset response["params"] = url>

		<cftry>

			<cfif session.perfilDeveloper EQ 1>
				<cfquery datasource="#application.datasource#" name="queryCount">
					SELECT
						COUNT(*) AS COUNT
					FROM
						dbo.grupo
					WHERE
						1 = 1
					<cfif IsDefined("url.grupo_nome") AND url.grupo_nome NEQ "">
						AND	grupo_nome LIKE <cfqueryparam value = "%#url.grupo_nome#%" CFSQLType = "CF_SQL_VARCHAR">
					</cfif>
				</cfquery>

				<cfquery datasource="#application.datasource#" name="query">
					SELECT
						grupo_id
						,grupo_nome
					FROM
						dbo.grupo
					WHERE
						1 = 1
					<cfif IsDefined("url.grupo_nome") AND url.grupo_nome NEQ "">
						AND	grupo_nome LIKE <cfqueryparam value = "%#url.grupo_nome#%" CFSQLType = "CF_SQL_VARCHAR">
					</cfif>
					ORDER BY
						grupo_nome ASC	
					
					<!--- Paginação --->
					OFFSET #URL.page * URL.limit - URL.limit# ROWS
					FETCH NEXT #URL.limit# ROWS ONLY;
				</cfquery>
			<cfelse>
				<cfquery datasource="#application.datasource#" name="queryCount">
					SELECT
						COUNT(*) AS COUNT
					FROM
						dbo.perfil_grupo AS perfil_grupo
								
					INNER JOIN grupo AS grupo
					ON grupo.grupo_id = perfil_grupo.grupo_id

					WHERE
						perfil_grupo.grupo_id IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#session.grupolist#" list="true">)
					AND per_id = <cfqueryparam value = "#session.perfilId#" CFSQLType = "CF_SQL_NUMERIC">
					<cfif IsDefined("url.grupo_nome") AND url.grupo_nome NEQ "">
						AND	grupo_nome LIKE <cfqueryparam value = "%#url.grupo_nome#%" CFSQLType = "CF_SQL_VARCHAR">
					</cfif>
				</cfquery>

				<cfquery datasource="#application.datasource#" name="query">
					SELECT
						perfil_grupo.per_id
						,perfil_grupo.grupo_id
						,grupo.grupo_nome
					FROM
						dbo.perfil_grupo AS perfil_grupo
								
					INNER JOIN grupo AS grupo
					ON grupo.grupo_id = perfil_grupo.grupo_id

					WHERE
						perfil_grupo.grupo_id IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#session.grupolist#" list="true">)
					AND per_id = <cfqueryparam value = "#session.perfilId#" CFSQLType = "CF_SQL_NUMERIC">
					<cfif IsDefined("url.grupo_nome") AND url.grupo_nome NEQ "">
						AND	grupo_nome LIKE <cfqueryparam value = "%#url.grupo_nome#%" CFSQLType = "CF_SQL_VARCHAR">
					</cfif>
					
					ORDER BY
						grupo_nome ASC	
					
					<!--- Paginação --->
					OFFSET #URL.page * URL.limit - URL.limit# ROWS
					FETCH NEXT #URL.limit# ROWS ONLY;
				</cfquery>
			</cfif>
		
			<cfset response["page"] = URL.page>	
			<cfset response["limit"] = URL.limit>	
			<cfset response["recordCount"] = queryCount.COUNT>
			<cfset response["query"] = queryToArray(query)>

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>
		</cftry>
		
		<cfreturn SerializeJSON(response)>
    </cffunction>

	<cffunction name="grupoAdmin" access="remote" returntype="String" httpmethod="GET" restPath="/admin"> 

		<cfset checkAuthentication()>
        
		<cfset response = structNew()>
		
		<cfset response["params"] = url>

		<cftry>

			<cfquery datasource="#application.datasource#" name="queryCount">
                SELECT
                    COUNT(*) AS COUNT
                FROM
                   	grupo
                WHERE
					1 = 1
				<cfif IsDefined("url.grupo_id") AND url.grupo_id NEQ "">
					AND	grupo_id = <cfqueryparam value = "#url.grupo_id#" CFSQLType = "CF_SQL_VARCHAR">
				</cfif> 

				<cfif IsDefined("url.grupo_nome") AND url.grupo_nome NEQ "">
					AND	grupo_nome LIKE <cfqueryparam value = "%#url.grupo_nome#%" CFSQLType = "CF_SQL_VARCHAR">
				</cfif> 
				
            </cfquery>

            <cfquery datasource="#application.datasource#" name="query">
                SELECT
					grupo_id
					,grupo_nome
                FROM
                   grupo
                WHERE 
					1 = 1
				<cfif IsDefined("url.grupo_id") AND url.grupo_id NEQ "">
					AND	grupo_id = <cfqueryparam value = "#url.grupo_id#" CFSQLType = "CF_SQL_VARCHAR">
				</cfif> 

				<cfif IsDefined("url.grupo_nome") AND url.grupo_nome NEQ "">
					AND	grupo_nome LIKE <cfqueryparam value = "%#url.grupo_nome#%" CFSQLType = "CF_SQL_VARCHAR">
				</cfif> 

				ORDER BY
					grupo_nome ASC	
                
                <!--- Paginação --->
                OFFSET #URL.page * URL.limit - URL.limit# ROWS
                FETCH NEXT #URL.limit# ROWS ONLY;
            </cfquery>
		
			<cfset response["page"] = URL.page>	
			<cfset response["limit"] = URL.limit>	
			<cfset response["recordCount"] = queryCount.COUNT>
			<cfset response["query"] = queryToArray(query)>

			<cfcatch>
				<cfset responseError(400, cfcatch.detail)>
			</cfcatch>
		</cftry>
		
		<cfreturn SerializeJSON(response)>
    </cffunction>

	<cffunction name="getById" access="remote" returntype="String" httpmethod="GET" 
		restpath="/{grupo_id}"> 

		<cfargument name="grupo_id" restargsource="Path" type="numeric"/>		
		
		<cfset checkAuthentication()>

		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		<cfset response["params"] = url>

		<cftry>

			<cfquery datasource="#application.datasource#" name="query">
                SELECT
					grupo_id
					,grupo_nome
				FROM
					grupo
				WHERE
				    grupo_id = <cfqueryparam value = "#arguments.grupo_id#" CFSQLType = "CF_SQL_NUMERIC">				
            </cfquery>
			
			<cfset response["query"] = queryToArray(query)>

			<cfreturn SerializeJSON(response)>

			<cfcatch>
				<cfset responseError(400, cfcatch.detail)>
			</cfcatch>
		</cftry>

    </cffunction>

	<cffunction name="grupoCreate" access="remote" returnType="String" httpMethod="POST">		
		<cfargument name="body" type="String">

		<cfset checkAuthentication()>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>

		<cftry>
			<!--- create --->
			<cfquery datasource="#application.datasource#" name="query">
				INSERT INTO 
					dbo.grupo
				(
					grupo_nome
				) 
				VALUES (
					<cfqueryparam value = "#arguments.body.grupo_nome#" CFSQLType = "CF_SQL_VARCHAR">
				);
			</cfquery>

			<cfset response["success"] = true>
			<cfset response["message"] = 'Ação realizada com sucesso!'>

			<cfcatch>
				<cfif cfcatch.ErrorCode EQ "23000">
					<cfset responseError(400, "Código do grupo já existe")>
				<cfelse>
					<cfset responseError(400, cfcatch.message)>
				</cfif>				
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="grupoUpdate" access="remote" returnType="String" httpMethod="PUT" 
		restpath="/{grupo_id}">
		
		<cfargument name="grupo_id" restargsource="Path" type="numeric"/>

		<cfargument name="body" type="String">

		<cfset checkAuthentication()>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
	
		<cftry>
			<!--- update --->
			<cfquery datasource="#application.datasource#">
				UPDATE 
					dbo.grupo  
				SET 
					grupo_nome = <cfqueryparam value = "#arguments.body.grupo_nome#" CFSQLType = "CF_SQL_VARCHAR">
				WHERE 
				    grupo_id = <cfqueryparam value = "#arguments.grupo_id#" CFSQLType = "CF_SQL_NUMERIC">
			</cfquery>

			<cfset response["success"] = true>
			<cfset response["message"] = 'Ação realizada com sucesso!'>

			<cfcatch>
				<cfif cfcatch.ErrorCode EQ "23000">
					<cfset responseError(400, "Código do grupo já existe")>
				<cfelse>
					<cfset responseError(400, cfcatch.detail)>
				</cfif>				
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="grupoRemove" access="remote" returnType="String" httpMethod="DELETE">		
		<cfargument name="body" type="String">

		<cfset checkAuthentication()>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
	
		<cftry>
			<!--- remove --->
			<cfloop array="#arguments.body#" index="i">
				<cfquery datasource="#application.datasource#">
					DELETE FROM 
						dbo.grupo 
					WHERE 
						grupo_id = <cfqueryparam value = "#i.grupo_id#" CFSQLType = "CF_SQL_NUMERIC">
				</cfquery>
			</cfloop>	

			<cfset response["success"] = true>			

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="grupoRemoveById" access="remote" returnType="String" httpMethod="DELETE"
		restpath="/{grupo_id}">
		
		<cfargument name="grupo_id" restargsource="Path" type="numeric"/>

		<cfset checkAuthentication()>

		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		
		<cftry>
			<!--- remove by id --->
			<cfquery datasource="#application.datasource#">
				DELETE FROM 
					dbo.grupo 
				WHERE 
				    grupo_id = <cfqueryparam value = "#arguments.grupo_id#" CFSQLType = "CF_SQL_NUMERIC">
			</cfquery>

			<cfset response["success"] = true>
			<cfset response["message"] = 'Ação realizada com sucesso!'>

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>
</cfcomponent>