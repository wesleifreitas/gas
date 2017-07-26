<cfcomponent rest="true" restPath="/">  

    <cfprocessingDirective pageencoding="utf-8">
    <cfset setEncoding("form","utf-8")> 
    
	<cfinclude template="util.cfm">
	<cfinclude template="security.cfm">

	<cffunction name="login" access="remote" returnType="String" httpMethod="POST" restPath="/login">
		<cfargument name="body" type="String">
        
		<cfset body = DeserializeJSON(arguments.body)>

        <cfif not IsDefined("body.setSession")>
            <cfset body.setSession = true>
        </cfif>

        <cfset response = structNew()>
		<cfset response["body"] = body>
        <cfset response["params"] = url>

        <cftry>
        
            <cfquery datasource="#application.datasource#" name="qLogin">  
                SELECT 
                    usu_id
                    ,usu_nome
                    ,usu_senha 
                    ,usu_mudarSenha
                    ,per_master
                    ,per_developer
                    ,usu_cpf
                    ,grupo_id
                    ,per_id
                    ,'' as perfil_grupo
                    ,'' as perfil_grupo_query
                FROM 
                    dbo.vw_usuario
                WHERE 
                    usu_login = <cfqueryparam value="#body.username#" cfsqltype="cf_sql_varchar">
                AND usu_senha = <cfqueryparam value="#hash(body.password, 'SHA-512')#" cfsqltype="cf_sql_varchar">
            </cfquery> 

            <cfif qLogin.recordCount GT 0>

                <!--- perfil_grupo - Start --->            
                <cfquery datasource="#application.datasource#" name="qPerfilGrupo">
                    SELECT
                        grupo_id                  
                    FROM
                        dbo.perfil_grupo
                    WHERE
                        grupo_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qLogin.grupo_id#">
                    AND	per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qLogin.per_id#">
                    ORDER BY
                        grupo_id
                </cfquery>		
                <cfset perfil_grupo = arrayNew(1)>
                <cfloop query="qPerfilGrupo">
                    <cfset arrayAppend(perfil_grupo, qPerfilGrupo.grupo_id)>
                </cfloop>		
                <cfset qLogin.perfil_grupo = arrayToList(perfil_grupo)>
                <cfset qLogin.perfil_grupo_query = QueryToArray(qPerfilGrupo)>	
                <!--- perfil_grupo - End ---> 

                <!--- acesso - Start --->
                <cfquery datasource="#application.datasource#" name="qAcesso">
                    SELECT
                        vw_menu.com_view as men_state
                    FROM
                        acesso AS acesso

                    INNER JOIN vw_menu AS vw_menu
                    ON vw_menu.men_id = acesso.men_id

                    WHERE
                        per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qLogin.per_id#">
                </cfquery>

                <cfset acesso = arrayNew(1)>
                <cfloop query="qAcesso">
                    <cfset arrayAppend(acesso, qAcesso.men_state)>
                </cfloop>	
                <!--- acesso - End ---> 

                <cfset response["success"] = true>
                <cfset response["message"] = "">

                <cfif qLogin.usu_mudarSenha EQ 1>
                    <cfset response["passwordChange"] = true>
                <cfelseif body.setSession>
                    <cflock timeout="20" throwontimeout="No" type="EXCLUSIVE" scope="session">
                        <cfset session.authenticated = true>					
                        <cfset session.userId = qLogin.usu_id>
                        <cfset session.userName = qLogin.usu_nome>  
                        <cfset session.userCpf = qLogin.usu_cpf>                            
                        <cfset session.perfilMaster = qLogin.per_master>    
                        <cfset session.perfilDeveloper = qLogin.per_developer>    
                        <cfset session.grupoId = qLogin.grupo_id>    
                        <cfset session.grupoList = qLogin.perfil_grupo>
                        <cfset session.perfilId = qLogin.per_id>
                        <cfset session.acesso = arrayToList(acesso)>   
                    </cflock>
                    <cfset response["session"] = session>
                </cfif>
            <cfelse>
                <cfset response["success"] = false>
                <cfset response["message"] = "Usuário e/ou senha incorreto(s)">
            </cfif>

            <cfset response["query"] = queryToArray(qLogin)>
            <cfset response["perfilDeveloper"] = qLogin.per_developer>
        
            <cfreturn SerializeJSON(response)>

            <cfcatch>
				<cfset responseError(400, cfcatch.detail)>
			</cfcatch>
		</cftry>
	</cffunction>
    
    <cffunction name="authenticated" access ="remote" returntype ="String" httpMethod="GET" restPath="/login">

        <cfset response = structNew()>

        <cfif StructKeyExists(session, "authenticated") AND session.authenticated>	
            <cfset response["authenticated"] = true>
            <!--- <cfset response["session"] = session> --->
        <cfelse>    
            <cfset response["authenticated"] = false>
        </cfif>

        <cfreturn SerializeJSON(response)>
    </cffunction>

    <cffunction name="redefine" access="remote" returnType="String" httpMethod="POST" restPath="/login/redefine">
        <cfargument name="body" type="String">

		<cfset body = DeserializeJSON(ARGUMENTS.body)>

        <cfset response = structNew()>

        <cftry>
            <cfquery datasource="#application.datasource#" name="query">
                SELECT
                    usu_id
                FROM
                    dbo.usuario	 
                WHERE
                    usu_login = <cfqueryparam cfsqltype="cf_sql_varchar" value="#body.username#">
                AND usu_senha = <cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(body.passwordOld, "SHA-512")#">
            </cfquery>
           
            <cfquery datasource="#application.datasource#" name="qQuery" result="queryResult">
                UPDATE
                    dbo.usuario	 
                SET
                    usu_senha = <cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(body.passwordNew, "SHA-512")#">	  
                    ,usu_mudarSenha = <cfqueryparam cfsqltype="cf_sql_bit" value="0">
                    ,usu_recuperarSenha = <cfqueryparam cfsqltype="cf_sql_bit" value="0">
                    ,usu_senhaData = GETDATE()
                WHERE
                    usu_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#query.usu_id#">
            </cfquery>	
                                             
            <cfset body = SerializeJSON({username: body.username,
                password: body.passwordNew,
                setSession: true})>

                <cfinvoke method="login" 
                    body="#body#"
                    returnVariable="login">

            <cfreturn login>

            <cfcatch>
                <cfset response["success"] = false>
                <cfset response["message"] = 'Erro ao se comunicar com o servidor'>
                <cfset response["cfcatch"] = cfcatch>                
            </cfcatch>

        </cftry>

        <cfreturn SerializeJSON(response)>

    </cffunction>

    <cffunction name="recover" access="remote" returnType="String" httpMethod="POST" restPath="/login/recover">
        <cfargument name="body" type="String">

		<cfset body = DeserializeJSON(ARGUMENTS.body)>

        <cfset response = structNew()>

        <cftry>
            <cfquery datasource="#application.datasource#" name="qQuery" result="queryResult">
                SELECT 
                    *
                FROM 
                    dbo.usuario
                WHERE
                    usu_login = <cfqueryparam cfsqltype="cf_sql_varchar" value="#body.username#">
                AND (usu_email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#body.email#">
                OR usu_ativo IN (0,2)) -- Usuário inativo, bloqueado)
            </cfquery>	

            <cfif qQuery.recordCount EQ 1>

                <cfif qQuery.usu_ativo NEQ 1>
                    <cfset response["success"] = false>

                    <cfswitch expression="#qQuery.usu_ativo#">
                        <cfcase value="0">
                            <cfset response["message"] = 'Este usuário está inativo'>			
                        </cfcase>
                        <cfcase value="2">
                            <cfset response["message"] = 'Este usuário está bloqueado'>			
                        </cfcase>
                        <cfdefaultcase>
                            <cfset response["message"] = ''>			
                        </cfdefaultcase>
                    </cfswitch>

                    <cfreturn SerializeJSON(response)>					
                </cfif>

                <cfset newPassword = randPassword()>

                <cfquery datasource="#application.datasource#">
                    UPDATE 
                        dbo.usuario  
                    SET 
                        usu_senha 		= <cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(variables.newPassword, "SHA-512")#">,
                        usu_recuperarSenha = <cfqueryparam cfsqltype="cf_sql_bit" value="1">,
                        usu_recuperarSenhaData = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">,
                        usu_mudarSenha = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
                    WHERE 
                        usu_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qQuery.usu_id#">;
                </cfquery>

                <cfquery name="qSMTP" datasource="#application.datasource#">
                    SELECT 
                        smtp_server
                        ,smtp_username
                        ,smtp_password
                        ,smtp_port
                    FROM 
                        dbo.smtp
                </cfquery>	
                
                <cfmail from="#qSMTP.smtp_username#"
                        type="html"
                        to="#body.email#"					
                        subject="[Sistema Gás] Recuperação de Senha"
                        server="#qSMTP.smtp_server#"
                        username="#qSMTP.smtp_username#" 
                        password="#qSMTP.smtp_password#"
                        port="#qSMTP.smtp_port#">

                    <strong>Este é um e-mail automático, por favor não responda.</strong>	
                    <br /><br />
                    Prezado(a) #qQuery.usu_nome#,
                    <br /><br />
                    Foi realizada uma solicitação de recuperação de senha para o login <b>#qQuery.usu_login#</b>
                    <br /><br />
                    Por favor acesse o sistema utilizando a senha temporária que está disponibilizada ao <strong>final deste e-mail</strong>.
                    <br /><br />
                    Ao acessar o sistema com a senha temporária, será solicitado o registro de uma nova senha.
                    <br /><br />
                    Obs: A senha temporária é válida por 24 Horas.
                    <br /><br />												
                    <br /><br /><br /><br /><br /><br /><br /><br /><br /><br />
                    <br /><br /><br /><br /><br /><br /><br /><br /><br /><br />
                    <br /><br /><br /><br /><br /><br /><br /><br /><br /><br />
                    <br /><br /><br /><br /><br /><br /><br /><br /><br /><br />
                    <cfoutput>
                        #variables.newPassword#
                    </cfoutput>	

                </cfmail>		

                <cfset response["success"] = true>	
                <cfset response["message"] = ''>
                <!--- <cfset response["newPassword"] = newPassword> --->			
            <cfelse>
                <cfset response["success"] = false>	
                <cfset response["message"] = 'Usuário e/ou e-mail incorreto(s)'>
            </cfif>
                    
            <cfset response["qQuery"] = QueryToArray(qQuery)>
                        
            <cfreturn SerializeJSON(response)>

            <cfcatch>
                <cfset response["success"] = false>
                <cfset response["message"] = 'Erro ao se comunicar com o servidor'>
                <cfset response["cfcatch"] = cfcatch>
                <cfreturn SerializeJSON(response)>
            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name = "logout" access ="remote" returntype ="String" httpMethod="POST" restPath="/logout">
        
        <cfset StructClear(session)>
        <cfset response = structNew()>
        <cfset response["sessionClear"] = true>

        <cfreturn SerializeJSON(response)>
    </cffunction>
</cfcomponent>