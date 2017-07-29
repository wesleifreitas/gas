<cfcomponent rest="true" restPath="/gas-cliente">  
	<cfinclude template="security.cfm">
	<cfinclude template="util.cfm">

	<cffunction name="get" access="remote" returntype="String" httpmethod="GET"> 

		<cfset checkAuthentication()>
        
		<cfset response = structNew()>
		
		<cfset response["params"] = url>

		<cftry>

			<cfquery datasource="#application.datasource#" name="queryCount">
                SELECT
                    COUNT(*) AS COUNT
                FROM
                    dbo.cliente AS cliente

				LEFT OUTER JOIN dbo.gas_status as gas_status
				ON gas_status.cli_id = cliente.cli_id

                WHERE
                    grupo_id = #grupoId#
                <cfif IsDefined("url.CLI_CPFCNPJ") AND url.CLI_CPFCNPJ NEQ "">
                    AND	cli_cpfCnpj = <cfqueryparam value = "#url.CLI_CPFCNPJ#" CFSQLType = "CF_SQL_VARCHAR">
                </cfif>
				<cfif IsDefined("url.CLI_CPFCNPJ") AND url.CLI_CPFCNPJ NEQ "">
                    AND	cli_cpfCnpj = <cfqueryparam value = "#url.CLI_CPFCNPJ#" CFSQLType = "CF_SQL_VARCHAR">
                </cfif>
				<cfif IsDefined("url.CLI_CEP") AND url.CLI_CEP NEQ "">
                    AND	cli_cep = <cfqueryparam value = "#url.CLI_CEP#" CFSQLType = "CF_SQL_VARCHAR">
                </cfif>
				<cfif IsDefined("url.GAS_STATUS") AND IsNumeric(url.GAS_STATUS)>
                    AND	gas_status = <cfqueryparam value = "#url.GAS_STATUS#" CFSQLType = "CF_SQL_INTEGER">
                </cfif>
            </cfquery>

            <cfquery datasource="#application.datasource#" name="query">
                SELECT
					cliente.cli_id
					,cli_ativo
					,cli_arquivo
					,cli_nome
					,cli_pessoa
					,cli_cpfCnpj
					,cli_rgInscricaoEstadual
					,cli_tel1
					,cli_tel2
					,cli_tel3
					,cli_tel4
					,cli_email
					,cli_nascimento
					,cli_endereco
					,cli_numero
					,cli_complemento
					,cli_bairro
					,cli_cidade
					,cli_uf
					,cli_cep
					,cli_data
					,grupo_id

					,gas_id
					,gas_status
					,gas_ultima_troca
					,gas_proxima_troca
					,gas_media
                FROM
                    dbo.cliente

				LEFT OUTER JOIN dbo.gas_status as gas_status
				ON gas_status.cli_id = cliente.cli_id
				
                WHERE
                     grupo_id = #grupoId#
                <cfif IsDefined("url.CLI_CPFCNPJ") AND url.CLI_CPFCNPJ NEQ "">
                    AND	cli_cpfCnpj = <cfqueryparam value = "#url.CLI_CPFCNPJ#" CFSQLType = "CF_SQL_VARCHAR">
                </cfif>
                <cfif IsDefined("url.CLI_NOME") AND url.CLI_NOME NEQ "">
                    AND	cli_nome COLLATE Latin1_general_CI_AI LIKE <cfqueryparam value = "%#url.CLI_NOME#%" CFSQLType = "CF_SQL_VARCHAR">
                </cfif>
				<cfif IsDefined("url.CLI_CEP") AND url.CLI_CEP NEQ "">
                    AND	cli_cep = <cfqueryparam value = "#url.CLI_CEP#" CFSQLType = "CF_SQL_VARCHAR">
                </cfif>
				<cfif IsDefined("url.GAS_STATUS") AND IsNumeric(url.GAS_STATUS)>
                    AND	gas_status = <cfqueryparam value = "#url.GAS_STATUS#" CFSQLType = "CF_SQL_INTEGER">
                </cfif>

                ORDER BY
                    gas_status
					,cli_cep
                
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

	<cffunction name="getById" access="remote" returntype="String" httpmethod="GET" restpath="/{id}"> 

		<cfargument name="id" restargsource="Path" type="numeric"/>
		
		<cfset checkAuthentication()>

		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		<cfset response["params"] = url>

		<cftry>

			<cfset rows = 100>
			<cfset myQuery = QueryNew("_id, nome, cpf, data, bateria, status", "bigint, varchar, varchar, date, integer, integer")> 
			<cfset newRow = QueryAddRow(MyQuery, rows)> 
			
			<cfloop from="1" to="#rows#" index="i">
				
				<cfset temp = QuerySetCell(myQuery, "_id", i, i)> 
				<cfset temp = QuerySetCell(myQuery, "nome", "Weslei Freitas", i)> 
				<cfset temp = QuerySetCell(myQuery, "cpf", '39145592845', i)>
				<cfset temp = QuerySetCell(myQuery, "data", now(), i)>
				<cfset temp = QuerySetCell(myQuery, "bateria", 1, i)>
				<cfset temp = QuerySetCell(myQuery, "status", 1, i)>

			</cfloop>

			<cfquery dbtype="query" name="query">  
				SELECT 
					_id
					,nome
					,cpf
					,data
					,bateria
					,status 
				FROM 
					myQuery
				WHERE
					_id = <cfqueryPARAM value="#arguments.id#" CFSQLType='CF_SQL_INTEGER'>  
			</cfquery>
			
			<cfset response["query"] = queryToArray(query)>

			<cfreturn SerializeJSON(response)>

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>
		</cftry>

    </cffunction>

	<cffunction name="create" access="remote" returnType="String" httpMethod="POST">
		<cfargument name="body" type="String">

		<cfset checkAuthentication()>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>

		<cftry>
			<!--- create --->
			<cfset response["success"] = true>
			<cfset response["message"] = 'Ação realizada com sucesso!'>

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="update" access="remote" returnType="String" httpMethod="PUT" restPath="/{id}">
		<cfargument name="id" restargsource="Path" type="numeric"/>
		<cfargument name="body" type="String">

		<cfset checkAuthentication()>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
	
		<cftry>
			<!--- update --->
			<cfset response["success"] = true>
			<cfset response["message"] = 'Ação realizada com sucesso!'>

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>	
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="remove" access="remote" returnType="String" httpMethod="DELETE">
		<cfargument name="body" type="String">

		<cfset checkAuthentication()>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
	
		<cftry>
			<!--- remove --->
			<cfset response["success"] = true>			

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="removeById" access="remote" returnType="String" httpMethod="DELETE" restPath="/{id}">
		<cfargument name="id" restargsource="Path" type="numeric"/>

		<cfset checkAuthentication()>

		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		
		<cftry>
			<!--- remove by id --->
			<cfset response["success"] = true>
			<cfset response["message"] = 'Ação realizada com sucesso!'>

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

</cfcomponent>