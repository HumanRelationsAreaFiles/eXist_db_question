<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:hraf="http://localhost.com/local" exclude-result-prefixes="xs hraf" version="2.0"><xsl:output method="html" encoding="utf-8" indent="no"/><xsl:template match="header"><h1><xsl:apply-templates/></h1></xsl:template><xsl:function name="hraf:contains" as="xs:string"><xsl:param name="block" as="xs:string"/><xsl:variable name="apos">'</xsl:variable><xsl:variable name="tokens"><xsl:for-each select="tokenize($block, '\|')"><xsl:value-of select="concat('contains(local-name(), ', $apos, ., $apos, ') or ')"/></xsl:for-each></xsl:variable><!-- lop off that trailing 'or' --><xsl:value-of select="substring($tokens, 0, string-length($tokens) - 3)"/></xsl:function><xsl:function name="hraf:blocks" as="xs:string*"><xsl:text>figure</xsl:text><xsl:text>list</xsl:text><xsl:text>quote</xsl:text><xsl:text>table</xsl:text><xsl:text>table.cals</xsl:text><xsl:text>p</xsl:text></xsl:function><xsl:function name="hraf:lookup_block_tag" as="element()"><xsl:param name="node" as="element()"/><xsl:variable name="node_name" select="$node/local-name()"/><xsl:choose><xsl:when test="$node_name = 'figure'"><el name="figure"/></xsl:when><xsl:when test="$node_name = 'quote'"><el name="blockquote"/></xsl:when><xsl:when test="$node_name = 'p'"><el name="div"/></xsl:when><xsl:when test="$node_name = 'table'"><el name="table" class="table"/></xsl:when><xsl:when test="$node_name = 'table.cals'"><el name="table"><xsl:attribute name="class" select="hraf:table_type($node)"/></el></xsl:when><xsl:when test="$node_name = 'list'"><el><xsl:attribute name="name" select="hraf:list_type($node)"/><xsl:attribute name="class" select="hraf:list_style($node)"/></el></xsl:when><xsl:otherwise><xsl:message terminate="yes"> ERROR: node is an expected block
                    element </xsl:message></xsl:otherwise></xsl:choose></xsl:function><!-- LISTS --><xsl:function name="hraf:list_style"><xsl:param name="list" as="node()"/><xsl:choose><xsl:when test="$list/@item.label"><xsl:value-of select="replace($list/@item.label/string(), '\.', '-')"/></xsl:when><xsl:otherwise>list-unstyled</xsl:otherwise></xsl:choose></xsl:function><xsl:function name="hraf:list_type"><xsl:param name="list" as="node()"/><xsl:choose><xsl:when test="$list/@list.type = 'ordered'"><xsl:text>ol</xsl:text></xsl:when><xsl:when test="$list/@list.type = 'unordered'"><xsl:text>ul</xsl:text></xsl:when><xsl:when test="$list/@list.type = 'definition'"><xsl:text>dl</xsl:text></xsl:when><xsl:otherwise>ul</xsl:otherwise></xsl:choose></xsl:function><!-- END LISTS --><!-- SRES --><xsl:template priority="2" match="p[(string-length(normalize-space()) != 0) or descendant::graphic] | bibl.item"><xsl:variable name="id"><xsl:choose><xsl:when test="@xml:id"><xsl:value-of select="@xml:id"/></xsl:when><xsl:when test="@id"><xsl:value-of select="@id"/></xsl:when><xsl:otherwise><xsl:message terminate="no"> WARN: No ID Found </xsl:message><xsl:text>NO-ID</xsl:text></xsl:otherwise></xsl:choose></xsl:variable><xsl:variable name="block_elements" select="hraf:blocks()"/><xsl:variable name="blocks" select="./node()[local-name() = ($block_elements)]"/><xsl:choose><xsl:when test="$blocks"><xsl:variable name="block_tag" select="hraf:lookup_block_tag($blocks[1])"/><xsl:apply-templates select="hraf:p($blocks[1]/preceding-sibling::node(), $id, @ocms)"/><xsl:element name="{$block_tag/@name/string()}"><xsl:attribute name="data-id" select="$id"/><xsl:if test="$block_tag/@class"><xsl:attribute name="class" select="$block_tag/@class/string()"/></xsl:if><xsl:if test="@ocms"><xsl:attribute name="data-ocms" select="@ocms"/></xsl:if><xsl:apply-templates select="$blocks[1]"/></xsl:element><xsl:apply-templates select="hraf:p($blocks[1]/following-sibling::node(), $id, @ocms)"/></xsl:when><xsl:otherwise><p><xsl:if test="@ocms"><xsl:attribute name="data-ocms" select="@ocms"/></xsl:if><xsl:attribute name="data-id" select="$id"/><xsl:apply-templates/></p></xsl:otherwise></xsl:choose></xsl:template><xsl:function name="hraf:p" as="element()"><xsl:param name="para"/><xsl:param name="id" as="xs:string"/><xsl:param name="ocms" as="xs:string?"/><p id="{$id}"><xsl:if test="$ocms"><xsl:attribute name="ocms" select="$ocms"/></xsl:if><xsl:sequence select="$para"/></p></xsl:function><xsl:template match="table/graphic"><xsl:variable name="alt"><xsl:choose><xsl:when test="                         ./preceding-sibling::node()[local-name() = ('title',                         'caption')]"><xsl:value-of select="                             ./preceding-sibling::node()[local-name() = ('title',                             'caption')][1]//text()"/></xsl:when><xsl:otherwise><xsl:text>Graphic displayed inside a table. Possibly a complex scanned table</xsl:text></xsl:otherwise></xsl:choose></xsl:variable><tr><td><img><xsl:attribute name="src"><xsl:value-of select="concat('http://192.168.10.249/graphics/', @name, '/scale/33')"/></xsl:attribute><xsl:attribute name="alt"><xsl:value-of select="$alt"/></xsl:attribute><xsl:attribute name="title"><xsl:value-of select="$alt"/></xsl:attribute><xsl:attribute name="class"><xsl:text>img-responsive</xsl:text></xsl:attribute></img></td></tr></xsl:template><!-- TABLE.CALS --><xsl:template name="colspec.colnum"><xsl:param name="colspec" select="."/><xsl:choose><xsl:when test="$colspec/@colnum"><xsl:value-of select="$colspec/@colnum"/></xsl:when><xsl:when test="$colspec/preceding-sibling::colspec"><xsl:variable name="prec.colspec.colnum"><xsl:call-template name="colspec.colnum"><xsl:with-param name="colspec" select="$colspec/preceding-sibling::colspec[1]"/></xsl:call-template></xsl:variable><xsl:value-of select="$prec.colspec.colnum + 1"/></xsl:when><xsl:otherwise>1</xsl:otherwise></xsl:choose></xsl:template><xsl:template name="calculate.colspan"><xsl:param name="entry" select="."/><xsl:variable name="namest" select="$entry/@namest"/><xsl:variable name="nameend" select="$entry/@nameend"/><xsl:variable name="scol"><xsl:call-template name="colspec.colnum"><xsl:with-param name="colspec" select="$entry/ancestor::tgroup/colspec[@colname = $namest]"/></xsl:call-template></xsl:variable><xsl:variable name="ecol"><xsl:call-template name="colspec.colnum"><xsl:with-param name="colspec" select="$entry/ancestor::tgroup/colspec[@colname = $nameend]"/></xsl:call-template></xsl:variable><xsl:value-of select="$ecol - $scol + 1"/></xsl:template><xsl:function name="hraf:table_type" as="xs:string"><xsl:param name="node" as="node()"/><xsl:choose><xsl:when test="$node/@frame = 'all'"><xsl:text>table table-bordered</xsl:text></xsl:when><xsl:otherwise><xsl:text>table</xsl:text></xsl:otherwise></xsl:choose></xsl:function><xsl:function name="hraf:table_entry_align" as="xs:string"><xsl:param name="align" as="xs:string"/><xsl:choose><xsl:when test="$align = 'left'"><xsl:text>text-left</xsl:text></xsl:when><xsl:when test="$align = 'right'"><xsl:text>text-right</xsl:text></xsl:when><xsl:when test="$align = 'center'"><xsl:text>text-center</xsl:text></xsl:when><xsl:otherwise><xsl:text>text-left</xsl:text></xsl:otherwise></xsl:choose></xsl:function><xsl:template match="table.cals"><xsl:variable name="class"><xsl:choose><xsl:when test="@frame = 'all'"><xsl:text>table table-bordered</xsl:text></xsl:when><xsl:otherwise><xsl:text>table</xsl:text></xsl:otherwise></xsl:choose></xsl:variable><table><xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute><xsl:apply-templates/></table></xsl:template><xsl:template match="table.cals/title | table/title"><caption><xsl:apply-templates/></caption></xsl:template><xsl:template match="thead"><thead><xsl:apply-templates/></thead></xsl:template><xsl:template match="row"><tr><xsl:apply-templates/></tr></xsl:template><xsl:template match="thead/row/entry"><th><xsl:if test="@align"><xsl:attribute name="class" select="hraf:table_entry_align(@align)"/></xsl:if><xsl:if test="@namest"><xsl:attribute name="colspan"><xsl:call-template name="calculate.colspan"/></xsl:attribute></xsl:if><xsl:apply-templates/></th></xsl:template><xsl:template match="entry"><td><xsl:if test="@align"><xsl:attribute name="class" select="hraf:table_entry_align(@align)"/></xsl:if><xsl:if test="@namest"><xsl:attribute name="colspan"><xsl:call-template name="calculate.colspan"/></xsl:attribute></xsl:if><xsl:apply-templates/></td></xsl:template><xsl:template match="tbody"><tbody><xsl:apply-templates/></tbody></xsl:template><xsl:template match="figure/title"><h4 class="text-muted"><xsl:apply-templates/></h4></xsl:template><xsl:template match="figure/caption"><figcaption><xsl:apply-templates/></figcaption></xsl:template><xsl:template match="list.item"><li><xsl:apply-templates/></li></xsl:template><xsl:template match="image | graphic"><xsl:variable name="alt"><xsl:choose><xsl:when test="                         ./preceding-sibling::node()[local-name() = ('title',                         'caption')]"><xsl:value-of select="                             ./preceding-sibling::node()[local-name() = ('title',                             'caption')][1]//text()"/></xsl:when><xsl:otherwise><xsl:text>Graphic displayed inside a table. Possibly a complex scanned table</xsl:text></xsl:otherwise></xsl:choose></xsl:variable><img><xsl:attribute name="src"><xsl:value-of select="concat('http://192.168.10.249/graphics/', @name, '/scale/45')"/></xsl:attribute><xsl:attribute name="alt"><xsl:value-of select="$alt"/></xsl:attribute><xsl:attribute name="title"><xsl:value-of select="$alt"/></xsl:attribute><xsl:attribute name="class"><xsl:text>img-responsive</xsl:text></xsl:attribute></img></xsl:template><xsl:template match="highlight[@rend = 'italic']"><em><xsl:apply-templates/></em></xsl:template><xsl:template match="highlight[@rend = 'underline']"><u><xsl:apply-templates/></u></xsl:template><xsl:template match="highlight[@rend = 'bold']"><strong><xsl:apply-templates/></strong></xsl:template><xsl:template match="title"><h3><xsl:apply-templates/></h3></xsl:template><xsl:template match="note.ref"><a title="scroll to note"><xsl:attribute name="href"><xsl:value-of select="concat('#', @idref)"/></xsl:attribute><xsl:apply-templates/></a></xsl:template><xsl:template match="note" mode="notes"><div class="note" data-type="{@type}"><a name="{@id}"> &#160;</a><xsl:if test="@type eq 'orig.pg.no'"><span class="text-muted">Original Page Number: </span></xsl:if><xsl:apply-templates/></div></xsl:template><xsl:template match="super"><sup><xsl:apply-templates/></sup></xsl:template><xsl:template match="xref"><span class="text-muted small xref">Cross-Reference: (<xsl:apply-templates/>) </span></xsl:template><xsl:template match="enote"><div class="enote" data-idref="{@idref}" data-id="{@xml:id}"><xsl:apply-templates/></div></xsl:template><xsl:template match="text()"><xsl:value-of select="normalize-space(.)"/></xsl:template><xsl:template match="page.break"><span class="page-break glyphicon glyphicon-file" data-pgno="{@pg.no}" title="Page {@pg.no} Originally Began Here"><xsl:value-of select="@pg.no"/></span></xsl:template><!-- DO NOTHING --><xsl:template match="note | p.ocm | a.ocm | b.ocm"/><xsl:template match="culture.change"/><xsl:template match="p[string-length(normalize-space()) = 0]"/><xsl:template match="/"><section><xsl:apply-templates select="//body"/></section><xsl:if test="//body//note"><footer class="notes"><xsl:apply-templates select="//body//note" mode="notes"/></footer></xsl:if></xsl:template></xsl:stylesheet>