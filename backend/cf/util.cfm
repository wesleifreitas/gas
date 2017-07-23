<cfprocessingDirective pageencoding="utf-8">
<cfset setEncoding("form","utf-8")> 

<!--- http://www.bennadel.com/blog/124-ask-ben-converting-a-query-to-an-array.htm --->
<cffunction 
    name       ="queryToArray" 
    access     ="public" 
    returntype ="array" 
    output     ="false"
    hint       ="Transforma uma query em uma array de structs.">
 
    <!--- Define arguments. --->
    <cfargument 
        name     ="Data" 
        type     ="query" 
        required ="yes"/>
 
    <cfscript>
 
        // Define the local scope.
        var LOCAL = StructNew();
 
        // Get the column names as an array.
        LOCAL.Columns = ListToArray( ARGUMENTS.Data.ColumnList );
 
        // Create an array that will hold the query equivalent.
        LOCAL.QueryArray = ArrayNew( 1 );
 
        // Loop over the query.
        for (LOCAL.RowIndex = 1 ; LOCAL.RowIndex LTE ARGUMENTS.Data.RecordCount ; LOCAL.RowIndex = (LOCAL.RowIndex + 1)){
 
            // Create a row structure.
            LOCAL.Row = StructNew();
 
            // Loop over the columns in this row.
            for (LOCAL.ColumnIndex = 1 ; LOCAL.ColumnIndex LTE ArrayLen( LOCAL.Columns ) ; LOCAL.ColumnIndex = (LOCAL.ColumnIndex + 1)){
 
                // Get a reference to the query column.                
                LOCAL.ColumnName = LOCAL.Columns[ LOCAL.ColumnIndex ];
                //LOCAL.ColumnName = lCase(LOCAL.Columns[ LOCAL.ColumnIndex ]); 
 
                // Store the query cell value into the struct by key.
                LOCAL.Row[ LOCAL.ColumnName ] = ARGUMENTS.Data[ LOCAL.ColumnName ][ LOCAL.RowIndex ];

                
                //metadata[LOCAL.ColumnName] = {type: "string", name: LOCAL.ColumnName };
            }   

            //LOCAL.Row.setmetadata(metadata);            
 
            // Add the structure to the query array.
            ArrayAppend( LOCAL.QueryArray, LOCAL.Row );
 
        }
 
        // Return the array equivalent.
        return( LOCAL.QueryArray );
 
    </cfscript>
    
</cffunction>

<!--- https://www.bennadel.com/blog/811-converting-iso-date-time-to-coldfusion-date-time.htm --->
<cffunction
    name="ISOToDateTime"
    access="public"
    returntype="string"
    output="false"
    hint="Converts an ISO 8601 date/time stamp with optional dashes to a ColdFusion date/time stamp.">

    <!--- Define arguments. --->
    <cfargument
        name="Date"
        type="string"
        required="true"
        hint="ISO 8601 date/time stamp."
        />

    <!---
        When returning the converted date/time stamp,
        allow for optional dashes.
    --->
    <cfreturn ARGUMENTS.Date.ReplaceFirst(
        "^.*?(\d{4})-?(\d{2})-?(\d{2})T([\d:]+).*$",
        "$1-$2-$3 $4"
        ) />
</cffunction>

<!--- 
This function converts XML variables into Coldfusion Structures. It also
returns the attributes for each XML node.
http://www.anujgakhar.com/2007/11/05/coldfusion-xml-to-struct/
http://www.anujgakhar.com/wp-content/uploads/2008/02/xml2struct.cfc.txt
--->

<cffunction name="ConvertXmlToStruct" access="public" returntype="struct" output="false"
                hint="Parse raw XML response body into ColdFusion structs and arrays and return it.">
    <cfargument name="xmlNode" type="string" required="true" />
    <cfargument name="str" type="struct" required="true" />
    <!---Setup local variables for recurse: --->
    <cfset var i = 0 />
    <cfset var axml = arguments.xmlNode />
    <cfset var astr = arguments.str />
    <cfset var n = "" />
    <cfset var tmpContainer = "" />
    
    <cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
    <cfset axml = axml[1] />
    <!--- For each children of context node: --->
    <cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
        <!--- Read XML node name without namespace: --->
        <cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
        <!--- If key with that name exists within output struct ... --->
        <cfif structKeyExists(astr, n)>
            <!--- ... and is not an array... --->
            <cfif not isArray(astr[n])>
                <!--- ... get this item into temp variable, ... --->
                <cfset tmpContainer = astr[n] />
                <!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
                <cfset astr[n] = arrayNew(1) />
                <!--- ... and reassing temp item as a first element of new array: --->
                <cfset astr[n][1] = tmpContainer />
            <cfelse>
                <!--- Item is already an array: --->
                
            </cfif>
            <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                    <!--- recurse call: get complex item: --->
                    <cfset astr[n][arrayLen(astr[n])+1] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
                <cfelse>
                    <!--- else: assign node value as last element of array: --->
                    <cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
            </cfif>
        <cfelse>
            <!---
                This is not a struct. This may be first tag with some name.
                This may also be one and only tag with this name.
            --->
            <!---
                    If context child node has child nodes (which means it will be complex type): --->
            <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                <!--- recurse call: get complex item: --->
                <cfset astr[n] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
            <cfelse>
                <!--- else: assign node value as last element of array: --->
                <!--- if there are any attributes on this element--->
                <cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
                    <!--- assign the text --->
                    <cfset astr[n] = axml.XmlChildren[i].XmlText />
                        <!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
                     <cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
                     <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
                         <cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
                             <!--- remove any namespace attributes--->
                            <cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
                         </cfif>
                     </cfloop>
                     <!--- if there are any atributes left, append them to the response--->
                     <cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
                         <cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
                    </cfif>
                <cfelse>
                     <cfset astr[n] = axml.XmlChildren[i].XmlText />
                </cfif>
            </cfif>
        </cfif>
    </cfloop>
    <!--- return struct: --->
    <cfreturn astr />
</cffunction>

<cffunction name="ConvertJsTreeXmlToStruct" access="public" returntype="struct" output="false"
                hint="Parse raw XML response body into ColdFusion structs and arrays and return it.">
    <cfargument name="xmlNode" type="string" required="true" />
    <cfargument name="str" type="struct" required="true" />
    <!---Setup local variables for recurse: --->
    <cfset var i = 0 />
    <cfset var axml = arguments.xmlNode />
    <cfset var astr = arguments.str />
    <cfset var n = "" />
    <cfset var tmpContainer = "" />
    
    <cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
    <cfset axml = axml[1] />
    <!--- For each children of context node: --->
    <cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
        <!--- Read XML node name without namespace: --->
        <cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
        <!--- If key with that name exists within output struct ... --->
        <cfif structKeyExists(astr, n)>
            <!--- ... and is not an array... --->
            <cfif not isArray(astr[n])>
                <!--- ... get this item into temp variable, ... --->
                <cfset tmpContainer = astr[n] />
                <!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
                <cfset astr[n] = arrayNew(1) />
                <!--- ... and reassing temp item as a first element of new array: --->
                <cfset astr[n][1] = tmpContainer />
            <cfelse>
                <!--- Item is already an array: --->
                
            </cfif>
            <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                    <!--- recurse call: get complex item: --->
                    <cfset astr[n][arrayLen(astr[n])+1] = ConvertJsTreeXmlToStruct(axml.XmlChildren[i], structNew()) />
                <cfelse>
                    <!--- else: assign node value as last element of array: --->
                    <cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
            </cfif>
        <cfelse>
            <!---
                This is not a struct. This may be first tag with some name.
                This may also be one and only tag with this name.
            --->
            <!---
                    If context child node has child nodes (which means it will be complex type): --->
            <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                <!--- recurse call: get complex item: --->
                <cfset astr[n] = ConvertJsTreeXmlToStruct(axml.XmlChildren[i], structNew()) />
            <cfelse>
                <!--- else: assign node value as last element of array: --->
                <!--- if there are any attributes on this element--->
                <cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
                    <!--- assign the text --->
                    <cfset astr[n] = axml.XmlChildren[i].XmlText />
                        <!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
                     <cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
                     <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
                         <cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
                             <!--- remove any namespace attributes--->
                            <cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
                         </cfif>
                     </cfloop>
                     <!--- if there are any atributes left, append them to the response--->
                     <cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
                         <cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
                    </cfif>
                <cfelse>
                     <cfset astr[n] = axml.XmlChildren[i].XmlText />
                </cfif>
            </cfif>
        </cfif>
    </cfloop>
    
    <cfif IsDefined("astr.children")>
        <cfif not isArray(astr.children)>
            <cfset childrenTemp = astr.children>
            <cfset astr.children = ArrayNew(1)>
            <cfset astr.children[1] = childrenTemp>
        </cfif>
    </cfif>

    <!--- return struct: --->
    <cfreturn astr />
</cffunction>

<cffunction 
    name       ="responseError" 
    access     ="private" 
    returntype ="void" 
    output     ="false">

    <cfargument name="errorCode" type="numeric" required="false" default="0" >
    <cfargument name="message" type="string" required="false" default="" >

    <cfif arguments.message eq "" and arguments.errorCode eq 401>
        <cfset arguments.message = "Usuário não autenticado ou sessão encerrada">
    </cfif>

    <cfthrow errorcode="#arguments.errorCode#" message="#arguments.message#">

</cffunction>