<cfcomponent rest="true" restPath="perfil">  
	<cfinclude template="security.cfm">
	<cfinclude template="util.cfm">

	<cfprocessingDirective pageencoding="utf-8">

	<cffunction name="perfil" access="remote" returntype="String" httpmethod="GET"> 
        
		<cfset checkAuthentication(state = ['perfil-usuario'])>
		 
		<cfset response = structNew()>
		
		<cfset response["params"] = url>

		<cftry>

			<cfquery datasource="#application.datasource#" name="queryCount">
                SELECT
                    COUNT(*) AS COUNT
                FROM
                   	vw_perfil
                WHERE
					1 = 1
				<cfif IsDefined("url.nome") AND url.nome NEQ "">
					AND	per_nome LIKE <cfqueryparam value = "%#url.nome#%" CFSQLType = "CF_SQL_VARCHAR">
				</cfif>
				<cfif not session.perfilDeveloper>
					AND per_developer <> 1
				</cfif>
            </cfquery>

            <cfquery datasource="#application.datasource#" name="query">
                SELECT
					per_id
					,per_nome
					,grupo_id
					,per_master
				FROM
					vw_perfil
				WHERE
					1 = 1
				<cfif IsDefined("url.nome") AND url.nome NEQ "">
					AND	per_nome LIKE <cfqueryparam value = "%#url.nome#%" CFSQLType = "CF_SQL_VARCHAR">
				</cfif>	
				<cfif not session.perfilDeveloper>
					AND per_developer <> 1
				</cfif>

				ORDER BY
					per_nome ASC
                
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
		restpath="/{id}"> 

		<cfargument name="id" restargsource="Path" type="numeric"/>

		<cfset checkAuthentication(state = ['perfil-usuario'])>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		<cfset response["params"] = url>

		<cftry>

			<cfquery datasource="#application.datasource#" name="query">
                SELECT
					per_id
					,per_nome
					,per_ativo
					,grupo_id
					,per_master
				FROM
					vw_perfil
				WHERE
					per_id = <cfqueryparam value = "#arguments.id#" CFSQLType = "CF_SQL_NUMERIC">
            </cfquery>
			
			<cfset response["query"] = queryToArray(query)>

			<cfcatch>
				<cfset responseError(400, cfcatch.message)>
			</cfcatch>
		</cftry>

		<cfreturn SerializeJSON(response)>
    </cffunction>
	
	<cffunction name="perfilCreate" access="remote" returnType="String" httpMethod="POST">		
		<cfargument name="body" type="String">

		<cfset checkAuthentication(state = ['perfil-usuario'])>
		
		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		
		<cftry>			
			<!--- create --->
			<cftransaction>
				<cfquery datasource="#application.datasource#" name="query" result="result">
					INSERT INTO 
						dbo.perfil
					(					
						per_master,
						per_ativo,
						per_nome,
						per_developer,
						per_resetarSenha,
						grupo_id
					) 
					VALUES (					
						<cfqueryparam value = "#body.per_master#" CFSQLType = "CF_SQL_BIT">,
						<cfqueryparam value = "#body.statusSelected#" CFSQLType = "CF_SQL_TINYINT">,
						<cfqueryparam value = "#body.nome#" CFSQLType = "CF_SQL_VARCHAR">,
						0,
						0,
						<cfqueryparam value = "#session.grupoId#" CFSQLType = "CF_SQL_BIGINT">
					);
				</cfquery>

				<cfif IsDefined("body.jstreeDataGrupo")>
					<cfloop array="#body.jstreeDataGrupo#" index="i">
						<cfif IsNumeric(i)>
							<cfquery datasource="#application.datasource#">
								INSERT INTO
									dbo.perfil_grupo
								(
									per_id,
									grupo_id
								) 
								VALUES (
									<cfqueryparam value = "#result.IDENTITYCOL#" CFSQLType = "CF_SQL_BIGINT">,
									<cfqueryparam cfsqltype="cf_sql_integer" value="#i#">
								);	
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>

				<cfif IsDefined("body.jstreeDataMenu")>
					<cfloop array="#body.jstreeDataMenu#" index="i">
						<cfquery datasource="#application.datasource#" result="queryResult">					
							INSERT INTO
								dbo.acesso
							(
								per_id,
								men_id,
								men_check
							) 
							VALUES (
								<cfqueryparam cfsqltype="cf_sql_bigint" value="#result.IDENTITYCOL#">,
								<cfqueryparam cfsqltype="cf_sql_bigint" value="#i#">,
								<cfqueryparam cfsqltype="cf_sql_bit" value="1">
							);					
						</cfquery>

						<cfquery datasource="#application.datasource#" name="qParent">
							SELECT
								men_idPai
							FROM
								dbo.menu
							WHERE
								men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#i#">
						</cfquery>

						<cfquery datasource="#application.datasource#" name="qParentAcesso">
							SELECT
								men_idPai
							FROM
								dbo.menu
							WHERE
								men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qParent.men_idPai#">
						</cfquery>

						<cfif qParent.recordCount GT 0 AND qParent.men_idPai GT 0>							
							<cfquery datasource="#application.datasource#">
								IF NOT EXISTS (	SELECT 
													per_id 
												FROM 
													dbo.acesso 
												WHERE 
													per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#result.IDENTITYCOL#">
												AND men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qParent.men_idPai#">)
								BEGIN
									INSERT INTO
										dbo.acesso
									(
										per_id,
										men_id,
										men_check
									) 
									VALUES (
										<cfqueryparam cfsqltype="cf_sql_bigint" value="#result.IDENTITYCOL#">,
										<cfqueryparam cfsqltype="cf_sql_bigint" value="#qParent.men_idPai#">,
										<cfqueryparam cfsqltype="cf_sql_bit" value="0">
									);
								END
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
			</cftransaction>

			<cfset response["success"] = true>
			<cfset response["message"] = 'Perfil criado com sucesso!'>

			<cfcatch>
				<cfset response["success"] = false>
				<cfset response["catch"] = cfcatch>	
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="perfilUpdate" access="remote" returnType="String" httpMethod="PUT" 
		restpath="/{id}">
		
		<cfargument name="id" restargsource="Path" type="numeric"/>		

		<cfargument name="body" type="String">

		<cfset checkAuthentication(state = ['perfil-usuario'])>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>

		
		<cftry>
			<cftransaction>					
				<!--- update --->
				<cfquery datasource="#application.datasource#">
					UPDATE 
						dbo.perfil  
					SET 
						per_ativo = <cfqueryparam value = "#body.statusSelected#" CFSQLType = "CF_SQL_TINYINT">,
						per_nome = <cfqueryparam value = "#body.nome#" CFSQLType = "CF_SQL_VARCHAR">,
						per_master = <cfqueryparam value = "#body.per_master#" CFSQLType = "CF_SQL_BIT">
					WHERE 
						per_id = <cfqueryparam value = "#arguments.id#" CFSQLType = "CF_SQL_BIGINT">				
				</cfquery>
				
				<cfquery datasource="#application.datasource#">
					DELETE FROM
						dbo.perfil_grupo							
					WHERE 
						per_id = <cfqueryparam value = "#arguments.id#" CFSQLType = "CF_SQL_BIGINT">
				</cfquery>	

				<cfif IsDefined("body.jstreeDataGrupo")>
					<cfloop array="#body.jstreeDataGrupo#" index="i">
						<cfif IsNumeric(i)>
							<cfquery datasource="#application.datasource#">
								INSERT INTO
									dbo.perfil_grupo
								(
									per_id,
									grupo_id
								) 
								VALUES (
									<cfqueryparam value = "#arguments.id#" CFSQLType = "CF_SQL_BIGINT">,
									<cfqueryparam cfsqltype="cf_sql_integer" value="#i#">
								);	
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>

				<cfquery datasource="#application.datasource#">
					DELETE FROM
						dbo.acesso
					WHERE
						per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.id#">
				</cfquery>

				<cfif IsDefined("body.jstreeDataMenu")>
					<cfloop array="#body.jstreeDataMenu#" index="i">
						<cfquery datasource="#application.datasource#" result="queryResult">
							DELETE FROM
								dbo.acesso
							WHERE
								per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.id#">
							AND men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#i#">

							INSERT INTO
								dbo.acesso
							(
								per_id,
								men_id,
								men_check
							) 
							VALUES (
								<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.id#">,
								<cfqueryparam cfsqltype="cf_sql_bigint" value="#i#">,
								<cfqueryparam cfsqltype="cf_sql_bit" value="1">
							);					
						</cfquery>

						<cfquery datasource="#application.datasource#" name="qParent">
							SELECT
								men_idPai
							FROM
								dbo.menu
							WHERE
								men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#i#">
						</cfquery>

						<cfquery datasource="#application.datasource#" name="qParentAcesso">
							SELECT
								men_idPai
							FROM
								dbo.menu
							WHERE
								men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qParent.men_idPai#">
						</cfquery>

						<cfif qParent.recordCount GT 0 AND qParent.men_idPai GT 0>							
							<cfquery datasource="#application.datasource#">
								IF NOT EXISTS (	SELECT 
													per_id 
												FROM 
													dbo.acesso 
												WHERE 
													per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.id#">
												AND men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qParent.men_idPai#">)
								BEGIN
									INSERT INTO
										dbo.acesso
									(
										per_id,
										men_id,
										men_check
									) 
									VALUES (
										<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.id#">,
										<cfqueryparam cfsqltype="cf_sql_bigint" value="#qParent.men_idPai#">,
										<cfqueryparam cfsqltype="cf_sql_bit" value="0">
									);
								END
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>				
			</cftransaction>

			<cfset response["success"] = true>
			<cfset response["message"] = 'Perfil atualizado com sucesso!'>

			<cfcatch>
				<cfset response["success"] = false>
				<cfset response["catch"] = cfcatch>	
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="perfilRemove" access="remote" returnType="String" httpMethod="DELETE">		
		<cfargument name="body" type="String">

		<cfset checkAuthentication(state = ['perfil-usuario'])>

		<cfset body = DeserializeJSON(arguments.body)>
		
		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
	
		<cftry>
			<!--- remove --->
			<cfloop array="#arguments.body#" index="i">
				<cfquery datasource="#application.datasource#">
					DELETE FROM 
						dbo.perfil 
					WHERE 
						per_id = <cfqueryparam value = "#i.per_id#" CFSQLType = "CF_SQL_NUMERIC">					
				</cfquery>
			</cfloop>			

			<cfset response["success"] = true>			

			<cfcatch>
				<cfset response["success"] = false>
				<cfset response["catch"] = cfcatch>	
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="perfilRemoveById" access="remote" returnType="String" httpMethod="DELETE"
		restpath="/{id}"
		>
		
		<cfargument name="id" restargsource="Path" type="numeric"/>		

		<cfset checkAuthentication(state = ['perfil-usuario'])>

		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		
		<cftry>
			<!--- remove by id --->
			<cfquery datasource="#application.datasource#">
				DELETE FROM 
					dbo.perfil 
				WHERE 
					per_id = <cfqueryparam value = "#arguments.id#" CFSQLType = "CF_SQL_NUMERIC">
			</cfquery>

			<cfset response["success"] = true>
			<cfset response["message"] = 'Perfil removido com sucesso!'>

			<cfcatch>
				<cfset response["success"] = false>
				<cfset response["catch"] = cfcatch>	
			</cfcatch>	
		</cftry>
		
		<cfreturn SerializeJSON(response)>
	</cffunction>

	<cffunction name="jsTreeGrupo" access="remote" returntype="String" httpmethod="GET" 
		restpath="/{perfil}/{grupo_id}"> 

		<cfargument name="perfil" restargsource="Path" type="numeric"/>
		<cfargument name="grupo_id" restargsource="Path" type="numeric"/>		
        
		<cfset checkAuthentication(state = ['perfil-usuario'])>

		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		<cfset response["params"] = url>

		<cftry>

			<cfquery datasource="#application.datasource#" name="qGrupo">
				SELECT
					grupo.grupo_id
					,grupo.grupo_nome
											
					,(SELECT 
							COUNT(1) 
						FROM 
							dbo.perfil_grupo AS perfil_check 
						WHERE 
							perfil_check.grupo_id = grupo.grupo_id
						AND perfil_check.per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.perfil#">
						AND grupo_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.grupo_id#">
					) AS grupo_check    
				FROM
					dbo.grupo AS grupo
				
				<cfif session.perfilDeveloper NEQ 1>
					WHERE grupo_id IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#session.grupolist#" list="true">)
				</cfif>
				
				ORDER BY
					grupo_nome
			</cfquery>
			
			<cfscript>			
				var jstree = structNew();
				var plugins = arrayNew(1);
				var data = arrayNew(1);
				var dataObj = structNew();

				arrayAppend(plugins, "wholerow");
				arrayAppend(plugins, "checkbox");

				dataObj["id"] = 0;
				dataObj["text"] = "Todos";
				dataObj["children"] = ArrayNew(1);

				for(item in qGrupo) {
					dataObjSub = structNew();
					dataObjSub["id"] = item.grupo_id;
					dataObjSub["text"] = item.grupo_nome;
					dataObjSub["state"]["selected"] = item.GRUPO_CHECK;
					arrayAppend(dataObj["children"], dataObjSub);
				}
				
				arrayAppend(data, dataObj);			
			
				jstree["plugins"] = plugins;
				jstree["core"]["themes"] = {"name": "proton", "responsive": true};
				jstree["core"]["data"] = data;
			</cfscript>		
			
			<cfset response["qGrupo"] = QueryToArray(qGrupo)>
			<cfset response["jstree"] = jstree>
			<cfset response["success"] = true>
			
			<cfcatch>
				<cfset response["success"] = false>
				<cfset response["catch"] = cfcatch>	
			</cfcatch>	
		
		</cftry>

		<cfreturn SerializeJSON(response)>
    </cffunction>

	<cffunction name="jsTreeMenu" access="remote" returntype="String" httpmethod="GET" restPath="/treeMenu"> 

		<cfset response = structNew()>
		<cfset response["arguments"] = arguments>
		<cfset response["params"] = url>

		<cftry>	
			<cfset inPro_id = url.projectId>

			<cfif not IsDefined("url.perfilId")>
				<cfset url.perfilId = -1>
			</cfif>

			<cfquery datasource="#application.datasource#" name="qMenu">
				SELECT
					menu.men_ativo
					,menu.men_sistema
					,menu.men_id
					,menu.men_nome
					,menu.men_idPai
					,menu.men_ordem
					,(
						SELECT 
							COUNT(1) 
						FROM 
							dbo.menu AS submenu 
						WHERE 
							pro_id      IN (#inPro_id#)
						AND menu.men_id = submenu.men_idPai 
						AND men_ativo   = 1
						AND men_sistema = 1
					) AS count_submenu
					,(
						SELECT 
							COUNT(1) 
						FROM 
							dbo.menu AS submenu 
						WHERE 
							pro_id              IN (#inPro_id#)
						AND submenu.men_idPai   = menu.men_idPai
						AND men_ativo           = 1 
						AND men_sistema         = 1
					) AS count_menu
					,(
					SELECT 
						COUNT(1) 
					FROM 
						dbo.acesso AS acesso_check 
					WHERE 
						pro_id              IN (#inPro_id#)
					AND acesso_check.men_id   = menu.men_id
					AND men_ativo           = 1 
					AND men_sistema         = 1
					<cfif url.perfilId GT -1>
						AND per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#url.perfilId#">
					</cfif>
				) AS acesso_check_per_id
				FROM
					dbo.menu AS menu

				<cfif session.perfilDeveloper NEQ 1>
					LEFT OUTER JOIN dbo.acesso AS acesso
					ON menu.men_id = acesso.men_id
				</cfif>

				WHERE
					pro_id      IN (#inPro_id#)
				AND men_ativo   = <cfqueryparam cfsqltype="cf_sql_bit" value="1"/>
				AND men_sistema = <cfqueryparam cfsqltype="cf_sql_bit" value="1"/>		 

				<cfif session.perfilDeveloper NEQ 1>
					AND acesso.per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#session.perfilId#">
				</cfif>

				ORDER BY
					menu.men_idPai
					,menu.men_ordem  					
			</cfquery>	

			<cfscript>
				var jstree = structNew();
				var plugins = arrayNew(1);
				var data = arrayNew(1);			

				arrayAppend(plugins, "wholerow");
				arrayAppend(plugins, "checkbox");		
			</cfscript>	

			<!--- <cfset dataTree = getRecursiveMenu(data = qMenu) /> --->

			<cfsavecontent variable="dataTree"><cfset getRecursiveMenu(data = qMenu, per_id = url.perfilId)></cfsavecontent>

			<cfset dataTree = ConvertJsTreeXmlToStruct(xmlParse(dataTree), structnew())>
			
			<cfset response["qMenu"] = qMenu>
			<cfset response["dataTree"] = dataTree>
				
			<cfscript>
				/*
				var jstree = structNew();
				var plugins = arrayNew(1);
				var data = arrayNew(1);
				var dataObj = structNew();

				arrayAppend(plugins, "wholerow");
				arrayAppend(plugins, "checkbox");

				dataObj["text"] = "Teste";
				dataObj["children"] = [{"text": "Teste selected"},{"state":{"selected": true}}];

				arrayAppend(data, dataObj);
				*/
			
				jstree["plugins"] = plugins;
				jstree["core"]["themes"] = {"name": "proton", "responsive": true};
				jstree["core"]["data"] = dataTree.children;
			</cfscript>		
			
			<cfset response["success"] = true>		
			<cfset response["arguments"] = arguments>
			<cfset response["jstree"] = jstree>			  
							
			<cfcatch>
				<cfset response["success"] = false>
				<cfset response["cfcatch"] = cfcatch>				
			</cfcatch>		
		</cftry>

		<cfreturn SerializeJSON(response)>
	</cffunction>

	<!--- private functions --->

	<cffunction
		name       ="getRecursiveMenu"
		access     ="private"
		returntype ="void"
		output     ="true"
		hint       ="Faz a saída dos menus filhos de um determinado menu pai">
	
		<!--- Define argumentos --->
		<cfargument 
			name ="dsn"		
			type ="string"
			required ="false"	
			default ="paybox_sql"	
			hint ="Data source name">

		<cfargument
			name     ="data"
			type     ="query"
			required ="true"
			hint     ="data dos menus"
			/>

		<cfargument
			name     ="per_id"
			type     ="numeric"
			required ="false"
			default  ="0"
			hint     ="ID do perfil"
			/>
	
		<cfargument
			name     ="men_idPai"
			type     ="numeric"
			required ="false"
			default  ="0"
			hint     ="ID do menu pai que o menu filho pertence"
			/>
		
		<!--- Define o scope LOCAL --->
		<cfset var LOCAL = StructNew() />
	
		<!--- Menus do menu pai --->
		<cfquery name="LOCAL.qMenu" dbtype="query">
			SELECT
				men_id
				,men_idPai
				,men_nome
				,men_ordem
				,count_submenu
				,count_menu
				,acesso_check_per_id
			FROM
				arguments.data
			WHERE
				men_ativo    = <cfqueryparam cfsqltype="cf_sql_bit"     value="1"/>
			AND men_sistema  = <cfqueryparam cfsqltype="cf_sql_bit"     value="1"/>
			AND men_idPai    = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.men_idPai#"/>
			ORDER BY
				men_ordem ASC				
		</cfquery>

		<!---     
			Verifica se existem algum menu filho
		--->
		<cfif LOCAL.qMenu.RecordCount>
			<cfif LOCAL.qMenu.men_idPai EQ 0>
				<cfoutput><root></cfoutput>
			</cfif>  
			<!--- Loop nos menus filhos --->
			<cfloop query="LOCAL.qMenu">  

				<cfquery datasource="#application.datasource#" name="qCheck">
					SELECT
						men_check
					FROM
						dbo.acesso
					WHERE
						per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.per_id#">
					AND men_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#LOCAL.qMenu.men_id#">
				</cfquery>


				<cfoutput><children><text>#LOCAL.qMenu.men_nome#</text><state><selected>#qCheck.men_check#</selected><opened>false</opened></state><id>#LOCAL.qMenu.men_id#</id></cfoutput>
				<!---
					Chama função recursiva
				--->
				<cfset getRecursiveMenu(
					data = arguments.data,
					per_id = arguments.per_id,
					men_idPai = LOCAL.qMenu.men_id
					)/>
				
				<cfoutput>
					</children>
					<!--- <children>null</children> --->
				</cfoutput>
			</cfloop>
			<cfif LOCAL.qMenu.men_idPai EQ 0>
				<cfoutput></root></cfoutput>
			</cfif>

		</cfif>   

		<cfreturn />
	</cffunction>

</cfcomponent>