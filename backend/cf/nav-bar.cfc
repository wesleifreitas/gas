<cfcomponent rest="true" restPath="/navBar">  
	<cfinclude template="util.cfm">
	
	<cffunction name="navBar" access="remote" returntype="String" httpmethod="GET"> 
        
        <cfset response = structNew()>
        <cfset response["params"] = url>

        <cfset inPro_id = "0">
        <cftry>
            <cfquery datasource="#application.datasource#" name="qUsuario">
                SELECT
                    usu_nome
                    ,per_id
                    ,per_developer
                    ,grupo_nome
                FROM
                    dbo.vw_usuario
                WHERE
                    usu_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#session.userId#">
            </cfquery>
            
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
                        <cfif session.userId GT -1 AND qUsuario.per_developer NEQ 1>
                            INNER JOIN dbo.acesso AS acesso
                            ON submenu.men_id = acesso.men_id
                        </cfif> 
                        WHERE 
                            pro_id      IN (#inPro_id#)
                        AND menu.men_id = submenu.men_idPai 
                        AND men_ativo   = 1
                        AND men_sistema = 1
                        <cfif session.userId GT -1 AND qUsuario.per_developer NEQ 1>
                            AND acesso.per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qUsuario.per_id#">
                        </cfif>
                    ) AS count_submenu
                    ,(
                        SELECT 
                            COUNT(1) 
                        FROM 
                            dbo.menu AS submenu 
                        <cfif session.userId GT -1 AND qUsuario.per_developer NEQ 1>
                            INNER JOIN dbo.acesso AS acesso
                            ON submenu.men_id = acesso.men_id
                        </cfif>
                        WHERE 
                            pro_id              IN (#inPro_id#)
                        AND submenu.men_idPai   = menu.men_idPai
                        AND men_ativo           = 1 
                        AND men_sistema         = 1
                        <cfif session.userId GT -1 AND qUsuario.per_developer NEQ 1>
                            AND acesso.per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qUsuario.per_id#">
                        </cfif>
                    ) AS count_menu

                    ,componente.com_view
                FROM
                    dbo.menu AS menu
                
                LEFT OUTER JOIN dbo.componente as componente
                ON componente.com_id = menu.com_id

                <cfif session.userId GT -1 AND qUsuario.per_developer NEQ 1>
                    INNER JOIN dbo.acesso AS acesso
                    ON menu.men_id = acesso.men_id
                </cfif>

                WHERE
                    pro_id      IN (#inPro_id#)
                AND men_ativo   = <cfqueryparam cfsqltype="cf_sql_bit" value="1"/>
                AND men_sistema = <cfqueryparam cfsqltype="cf_sql_bit" value="1"/>
                <cfif session.userId GT -1 AND qUsuario.per_developer NEQ 1>
                    AND acesso.per_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qUsuario.per_id#">
                </cfif>
                ORDER BY
                    menu.men_idPai
                    ,menu.men_ordem             
            </cfquery>
            

            <cfsavecontent variable = "navBar">               
                <cfset getRecursiveNavBar(data = qMenu) />
            </cfsavecontent>

            <cfsavecontent variable = "sideMenu">               
                <cfset getRecursiveNavBar(data = qMenu, sideMenu = true) />
            </cfsavecontent>

            <cfif IsDefined("url.sidemenu") AND url.sidemenu>
                <cfset response['sideMenu'] = "<md-sidemenu>#sideMenu#</md-sidemenu>">
                <!--- <cfset response['sideMenu'] = ConvertJsTreeXmlToStruct(xmlParse(response['navBar']), structnew())> --->
            <cfelse>
                <cfset response['navBar'] = "<md-menu-bar>#navBar#</md-menu-bar>">
            </cfif>
           
            <cfcatch>
				<cfset responseError(400, cfcatch.detail)>
			</cfcatch>	
		</cftry>
        
        <cfreturn SerializeJSON(response)>

    </cffunction>

    <!--- Função desenvolvida baseada em:
    http://www.bennadel.com/blog/1069-ask-ben-simple-recursion-example.htm --->
    <cffunction
        name="getRecursiveNavBar"
        access="public"
        returntype="void"
        output="true"
        hint="Faz a saída dos menus filhos de um determinado menu pai">
    
        <!--- Define argumentos --->
        <cfargument
            name="data"
            type="query"
            required="true"
            hint=""
            />
    
        <cfargument
            name="men_idPai"
            type="numeric"
            required="false"
            default="0"
            hint=""
            />

        <cfargument
            name="sideMenu"
            type="boolean"
            required="false"
            default="false"
            hint=""
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
                ,com_view
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
            <!--- Loop nos menus filhos --->
            <cfloop from="1" to="#LOCAL.qMenu.RecordCount#" index="i">
                <cfif not arguments.sideMenu>
                    <!--- Possui submenu? --->
                    <cfif LOCAL.qMenu.count_submenu[i] GT 0>
                        <!--- Verificar é menu base --->
                        <cfif LOCAL.qMenu.men_idPai[i] EQ 0>
                            <md-menu>
                                <button ng-click="$mdOpenMenu()">
                                    #LOCAL.qMenu.men_nome[i]#
                                </button>
                                <md-menu-content>
                                <!---
                                    Chamar função recursiva
                                --->
                                <cfset getRecursiveNavBar(
                                    data = arguments.data,
                                    men_idPai = LOCAL.qMenu.men_id[i]) />
                                </md-menu-content>
                            </md-menu>
                        <cfelse>
                            <md-menu-item>
                                <md-menu>
                                    <md-button ng-click="$mdOpenMenu()">
                                        #LOCAL.qMenu.men_nome[i]#
                                    </md-button>
                                    <md-menu-content>
                                    <!---
                                        Chamar função recursiva
                                    --->
                                    <cfset getRecursiveNavBar(
                                        data = arguments.data,
                                        men_idPai = LOCAL.qMenu.men_id[i]) />
                                    </md-menu-content>
                                </md-menu>
                            </md-menu-item>
                        </cfif>
                    <!--- Verificar se possui idPai --->
                    <cfelseif LOCAL.qMenu.men_idPai[i] GT 0>
                        <md-menu-item>
                            <md-button ng-click="showView('#LOCAL.qMenu.men_id[i]#')">
                                #LOCAL.qMenu.men_nome[i]#
                            </md-button>
                        </md-menu-item>
                    </cfif>
                <cfelse> <!--- SIDE MENU --->
                    <!--- Possui submenu? --->
                    <cfif LOCAL.qMenu.count_submenu[i] GT 0>
                        <!--- Verificar é menu base --->
                        <cfif LOCAL.qMenu.men_idPai[i] EQ 0>
                            <md-sidemenu-group>
                                <md-sidemenu-content md-icon="" md-heading="#LOCAL.qMenu.men_nome[i]#" md-arrow="true">
                                <!---
                                    Chamar função recursiva
                                --->
                                <cfset getRecursiveNavBar(
                                    data = arguments.data,
                                    men_idPai = LOCAL.qMenu.men_id[i],
                                    sideMenu = true) />
                               
                                </md-sidemenu-content>
                             </md-sidemenu-group>
                        <cfelse>
                            <md-sidemenu-group>
                                <md-sidemenu-content md-icon="" md-heading="#LOCAL.qMenu.men_nome[i]#" md-arrow="true">
                                    <!---
                                        Chamar função recursiva
                                    --->
                                    <cfset getRecursiveNavBar(
                                        data = arguments.data,
                                        men_idPai = LOCAL.qMenu.men_id[i],
                                        sideMenu = true) />
                                    </md-menu-content>
                                </md-sidemenu-content>
                             </md-sidemenu-group>
                        </cfif>
                    <!--- Verificar se possui idPai --->
                    <cfelseif LOCAL.qMenu.men_idPai[i] GT 0>
                        <md-sidemenu-button ui-sref="#LOCAL.qMenu.com_view#" ng-click="showView('#LOCAL.qMenu.com_view#')">
                            #LOCAL.qMenu.men_nome[i]#                            
                        </md-sidemenu-button>
                    </cfif>
                </cfif>
            </cfloop>
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="view" access="remote" returntype="String" httpmethod="GET" restPath="/view"> 

        <cfquery name="query" datasource="#application.datasource#">
            
            WITH pxProjectMenuRecursivo(men_id, men_nome, men_nivel, men_nomeCaminho, men_ordem, men_idPai, com_view, com_icon)
            AS
            (
                SELECT 
                    men_id
                    ,men_nome
                    ,1 AS 'men_nivel'
                    ,CAST(men_nome AS VARCHAR(255)) AS 'men_nomeCaminho'
                    ,men_ordem
                    ,men_idPai
                    ,com_view
                    ,com_icon
                FROM 
                    dbo.vw_menu 
                WHERE 
                    (men_idPai IS NULL OR men_idPai = 0)
                                        
                UNION ALL
                                    
                <!--- Parte recursiva --->
                SELECT 
                    m.men_id
                    ,m.men_nome
                    ,c.men_nivel + 1 AS 'men_nivel',
                    CAST((c.men_nomeCaminho + ' » ' + m.men_nome) AS VARCHAR(255)) 'men_nomeCaminho'
                    ,m.men_ordem
                    ,m.men_idPai
                    ,m.com_view
                    ,m.com_icon
                FROM 
                    dbo.vw_menu m 
                INNER JOIN 
                    pxProjectMenuRecursivo c 
                ON 
                    m.men_idPai = c.men_id
                                
            )
            SELECT 
                men_nivel
                ,men_nomeCaminho
                ,men_ordem
                ,men_idPai
                ,men_id
                ,com_view 
                ,com_icon
            FROM 
                pxProjectMenuRecursivo
            WHERE 
                men_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.menu#">

        </cfquery>

        <cfset response = structNew()> 
        <cfset response['query'] = queryToArray(query)> 
        
        <cfreturn SerializeJSON(response)>

    </cffunction>
</cfcomponent>