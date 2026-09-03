#include "totvs.ch"
*/------------------------------------------------------------------*/
*/ Rotina: LocxUser  											    */
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna postos avancados e localidades permitidas para o usuário */
*/ nas consultas F3.                                                */
*/------------------------------------------------------------------*/
User Function LocxUser(nTipo, cAlias)
Static aCodPost := {}
Static aLocalId := {}
Static lLoaded  := .F.
Static cLastUser := ""

Local cUsuario := __cUserId
Local cAdmins  := GetMv("LC_USERADM",, "000000")
Local cPrefixo := SubStr(cAlias, 2, 2)
Local cCampo   := ""
Local cValor   := ""
Local lRet     := .F.

// -------------------------------------------------------
// Administradores: sem restricao
// -------------------------------------------------------
If cUsuario $ cAdmins
    Return .T.
EndIf

// -------------------------------------------------------
// Carrega alada do SZ4 apenas 1x por usuario
// -------------------------------------------------------
If !lLoaded .Or. cLastUser != cUsuario

    aCodPost := {}
    aLocalId := {}

    BeginSQL Alias "SZ4QRY"
        SELECT Z4_USER, Z4_CODPOST, Z4_LOCALID
        FROM %table:SZ4%
        WHERE Z4_FILIAL = %xFilial:SZ4%
            AND Z4_USER = %Exp:cUsuario%
            AND %NotDel%
    EndSQL

    While SZ4QRY->(!EOF())
        If aScan(aCodPost, SZ4QRY->Z4_CODPOST) == 0
            aAdd(aCodPost, AllTrim(SZ4QRY->Z4_CODPOST))
        EndIf
        If aScan(aLocalId, SZ4QRY->Z4_LOCALID) == 0
            aAdd(aLocalId, AllTrim(SZ4QRY->Z4_LOCALID))
        EndIf
        SZ4QRY->(DbSkip())
    End

    SZ4QRY->(DbCloseArea())

    lLoaded  := .T.
    cLastUser := cUsuario
EndIf

// -------------------------------------------------------
// Usuario sem alada: nao mostra nada
// -------------------------------------------------------
If Len(aCodPost) == 0 .And. Len(aLocalId) == 0
    Return .F.
EndIf

// -------------------------------------------------------
// Avalia o registro atual
// -------------------------------------------------------
If nTipo == 1
    cCampo := cAlias + "->" + cPrefixo + "_CODPOST"
    cValor := AllTrim(&cCampo)
    lRet   := (aScan(aCodPost, cValor) > 0)
Else
    cCampo := cAlias + "->" + cPrefixo + "_LOCALID"
    cValor := AllTrim(&cCampo)
    lRet   := (aScan(aLocalId, cValor) > 0)
EndIf

Return lRet

*/------------------------------------------------------------------*/
*/ Rotina: MBLocxUsr											    */
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna postos avancados e localidades permitidas para o usuário */
*/ nas consultas F3.                                                */
*/------------------------------------------------------------------*/
User Function MBLocxUsr(nTipo, cAlias)

Local cFiltro := SubStr(cAlias, 2,2) + If(nTipo == 1, "_CODPOST $ '", "_LOCALID $ '")
Local cUsuario := __cUserId
Local cAdmins  := GetMV("LC_USERADM",, "000000")

// Administradores do módulo não retorna filtro.
If cUsuario $ cAdmins
    Return("")
EndIf

BeginSQL Alias "SZ4QRY"
    SELECT
        Z4_USER, Z4_CODPOST, Z4_LOCALID
    FROM
        %tABLE:SZ4%
    WHERE
        Z4_FILIAL = %xFilial:SZ4% AND
        Z4_USER = %Exp:cUsuario% AND
        %Notdel%
EndSQL

// Usuário sem alçada não mostra nenhum registro.
If SZ4QRY->(EOF())
    cFiltro += "XXXXXX'"
    return(cFiltro)
EndIf

While SZ4QRY->(!EOF())
    If nTipo == 1
        If At(SZ4QRY->Z4_CODPOST, cFiltro) == 0
            cFiltro += SZ4QRY->Z4_CODPOST + ";"
        EndIf
    Else
        If At(SZ4QRY->Z4_LOCALID, cFiltro) == 0
            cFiltro += SZ4QRY->Z4_LOCALID + ";"
        EndIf
    EndIf
    SZ4QRY->(DbSkip())
End
SZ4QRY->(DbCloseArea())

If !Empty(cFiltro)
    cFiltro := Substr(cFiltro, 1, Len(cFiltro) - 1) + "'"
EndIf

Return(cFiltro)

*/------------------------------------------------------------------*/
*/ Rotina: RetDocKit												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna o documento onde o patrimônio está alocado.				*/
*/------------------------------------------------------------------*/
User Function RetDocKit(cPatrim)

Local aRet := {"", ""}

BeginSQL Alias "Z42QRY"
	SELECT 
		ZI_DOC, ZI_CODKIT, ZI_NUMLOC, ZI_NUMSEQ
	FROM 
		%Table:SZI%
	WHERE
		ZI_FILIAL = %xFilial:SZI% AND
		ZI_PATRIM = %Exp:cPatrim% AND
		%NotDel%
EndSQL

If !Z42QRY->(EOF())
	aRet := {Z42QRY->ZI_DOC, Z42QRY->ZI_CODKIT, Z42QRY->ZI_NUMLOC, Z42QRY->ZI_NUMSEQ}
EndIf
Z42QRY->(DbCloseArea())

Return(aRet)

*/------------------------------------------------------------------*/
*/ Rotina: RetDocPat												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna o documento onde o patrimônio está alocado.				*/
*/------------------------------------------------------------------*/
User Function RetDocPat(cPatrim)

Local aRet := {"","","",""}

BeginSQL Alias "Z42QRY"
	SELECT 
		ZI_DOC, ZI_STATUS, ZI_ISSI, ZI_NUMSEQ
	FROM 
		%Table:SZI%
	WHERE
		ZI_FILIAL = %xFilial:SZI% AND
		ZI_PATRIM = %Exp:cPatrim% AND
        ZI_STATUS = 'A' AND
		%NotDel%
EndSQL

If !Z42QRY->(EOF())
	aRet := {Z42QRY->ZI_DOC, Z42QRY->ZI_STATUS, AllTrim(Z42QRY->ZI_ISSI), Z42QRY->ZI_NUMSEQ}
EndIf
Z42QRY->(DbCloseArea())

Return(aRet)

*/------------------------------------------------------------------*/
*/ Rotina: RetPatDoc												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna o patrimônio do documento informado.	        			*/
*/------------------------------------------------------------------*/
User Function RetPatDoc(cNumSeq)

Local aRet := {}

BeginSQL Alias "Z42QRY"
	SELECT 
		ZI_PATRIM, ZI_ISSI
	FROM 
		%Table:SZI%
	WHERE
		ZI_FILIAL = %xFilial:SZI% AND
		ZI_NUMSEQ = %Exp:cNumSeq% AND
		ZI_PATRIM <> '' AND
		%NotDel%
EndSQL

If !Z42QRY->(EOF())
	aRet := {AllTrim(Z42QRY->ZI_PATRIM), AllTrim(Z42QRY->ZI_ISSI)}
EndIf
Z42QRY->(DbCloseArea())

Return(aRet)

*/------------------------------------------------------------------*/
*/ Rotina: RetNivelCC												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna os níveis do centro de custo.            				*/
*/------------------------------------------------------------------*/
User Function RetNivelCC(cCC)

Local aRet := {}

BeginSQL Alias "SZBQRY"
	SELECT 
		ZB_CODIGO, ZB_DESCRI, ZB_NIVEL
	FROM 
		%Table:SZB%
	WHERE
		ZB_FILIAL = %xFilial:SZB% AND
		ZB_CC = %Exp:cCC% AND
		%NotDel%
EndSQL

While !SZBQRY->(EOF())
	aAdd(aRet, {SZBQRY->ZB_CODIGO, SZBQRY->ZB_DESCRI, SZBQRY->ZB_NIVEL})
    SZBQRY->(DbSkip())
End
SZBQRY->(DbCloseArea())

If Empty(aRet)
    aRet := {{"","","","",""}}
EndIf

Return(aRet)

*/------------------------------------------------------------------*/
*/ Rotina: RetNumLoc												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna próximo número de locação.               				*/
*/------------------------------------------------------------------*/
User Function RetNumLoc()

Local cNum := GetMV("AL_NUMLOC")

cNum := Soma1(cNum)

PutMV("AL_NUMLOC", cNum)

Return(cNum)

*/------------------------------------------------------------------*/
*/ Rotina: RetNumSeq												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna próximo número sequencia de locação.        				*/
*/------------------------------------------------------------------*/
User Function RetNumSeq()

Local cNum := GetMV("AL_NUMSEQ")

cNum := Soma1(cNum)

PutMV("AL_NUMSEQ", cNum)

Return(cNum)

*/------------------------------------------------------------------*/
*/ Rotina: ISSIOK 													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Verifica se a ISSI já foi usada.     							*/
*/------------------------------------------------------------------*/
User Function ISSIOK(cISSI)

Local nX        := 0
Local nTotal    := 0
Local cISSIGrid := ""
Local cPatGrid  := ""
Local oModel    := FWModelActive()
Local oGrid     := oModel:GetModel("SZIDETAIL")

If Empty(cISSI)
    Return(.T.)
EndIf

BeginSQL Alias "Z42QRY"
    SELECT
        ZI_ISSI, ZI_PATRIM
    FROM
        %Table:SZI%
    WHERE
        ZI_FILIAL = %xFilial:SZI% AND
        ZI_STATUS = "A" AND
        ZI_ISSI = %Exp:cISSI% AND
        %NotDel%
EndSQL

If !Z42QRY->(EOF())
    MsgInfo("Esse ISSI já foi utilizado na entrega do patrimônio [" + AllTrim(Z42QRY->ZI_PATRIM) + "]", "Atenção")
    Z42QRY->(DbCloseArea())
    Return(.F.)
EndIf
Z42QRY->(DbCloseArea())

If oGrid <> Nil
    nTotal := oGrid:Length()

    For nX := 1 to nTotal
        oGrid:GoLine(nX)
        
        cISSIGrid := oGrid:GetValue("ZI_ISSI")
        cPatGrid  := oGrid:GetValue("ZI_PATRIM")

        If cISSIGrid == cISSI
            MsgInfo("Esse ISSI já foi utilizado na entrega do patrimônio [" + AllTrim(cPatGrid) + "]", "Atenção")
            Return(.F.)
        EndIf
    Next nX
EndIf

Return(.T.)

*/------------------------------------------------------------------*/
*/ Rotina: PatrimOri												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Busca o patrimônio de origem da locação através do substituto.	*/
*/------------------------------------------------------------------*/
User Function PatrimOri(cDocOri)

Local cDoc    := ""
Local aPatrim := {}

BeginSQL Alias "SZIPAT"
    SELECT 
        ZI_DOC, ZI_PATRIM, ZH_STATUS, ZI_DATAMOV
    FROM 
        %TAble:SZI% SZI
        INNER JOIN %Table:SZH% SZH ON ZH_DOC = ZI_DOC
    WHERE
        ZI_FILIAL = %xFilial:SZI% AND
        ZI_DOCSUBS = %Exp:cDocOri% AND
        SZI.%NotDel% AND
        SZH.%NotDel%
EndSQL

If !SZIPAT->(EOF())
    cDoc := SZIPAT->ZI_DOC

    If SZIPAT->ZH_STATUS == "A"
        aPatrim := {SZIPAT->ZI_PATRIM, StoD(SZIPAT->ZI_DATAMOV)}
    Else
        SZIPAT->(DbCloseArea())
        aPatrim := PatrimOri(cDoc)
    EndIf
EndIf

SZIPAT->(DbCloseArea())

Return(aPatrim)


*/------------------------------------------------------------------*/
*/ Rotina: PesqPat													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Consulta patrimônios.                                			*/
*/------------------------------------------------------------------*/
*/ cCodPosto : Posto avançado                             			*/
*/ cLocalid  : Localidade                                 			*/
*/ cProduto  : Produto a pesquisar                         			*/
*/ lAltera   : Permite alterar patrimônnio                 			*/
*/ lDisp     : Mostra somente disponível                   			*/
*/ cArmazem  : Armazem                                 			    */
*/------------------------------------------------------------------*/
User Function PesqPat(cCodPosto, cLocalid, cProduto, cDoc, cSerie, lDisp, cArmazem)

Local oGet
Local oButton1
Local oSay1, oSay2
Local nX
Local nOpcA        := 0
Local cStatus      := ""
Local aHeaderEx    := {}
Local aColsEx      := {}
Local aFields      := {"ZJ_PATRIM", "ZJ_NUMSER", "ZJ_ESN", "ZJ_LOCADO"}
Local aAlterFields := {}

Default lDisp    := .T.
Default lAltera  := .F.
Default cDoc     := ""
Default cSerie   := ""
Default cArmazem := ""

SZJ->(DbSetOrder(4)) // Cód. Posto + Localidade + Produto + Documento + Série
SB1->(DbSetOrder(1)) // Código
SX3->(dbSetOrder(2)) // Campo

For nX := 1 to Len(aFields)
    SX3->(dbSeek(aFields[nX]))
	If X3USO(SX3->X3_USADO)
		AADD(aHeaderEx, {Trim(X3TITULO()),;
		SX3->X3_CAMPO   ,;
		SX3->X3_PICTURE ,;
		SX3->X3_TAMANHO ,;
		SX3->X3_DECIMAL ,;
		SX3->X3_VALID   ,;
		SX3->X3_USADO   ,;
		SX3->X3_TIPO    ,;
		SX3->X3_ARQUIVO ,;
		SX3->X3_CONTEXT })
    EndIf
Next

nUsado := Len(aHeaderEx)

If !SZJ->(DbSeek(xFilial("SZJ") + cCodPosto + cLocalid + cProduto + cDoc + cSerie))
    MsgInfo("Produto sem registros de patrimônio", "Atenção")
    Return
EndIf

SB1->(DbSeek(xFilial("SB1") + cProduto))

If !Empty(cDoc)
    While SZJ->ZJ_FILIAL == xFilial("SZJ") .and.;
        SZJ->ZJ_CODPOST == cCodPosto .and.;
        SZJ->ZJ_LOCALID == cLocalid .and.;
        SZJ->ZJ_PRODUTO == SB1->B1_COD .and.;
        SZJ->ZJ_DOC == cDoc .and.;
        SZJ->ZJ_SERIE == cSerie .and. !SZJ->(EOF())

        If lDisp .and. SZJ->ZJ_LOCADO == "S"
            SZJ->(DbSkip())
            Loop
        EndIf

        Aadd(aColsEx, Array(nUsado + 1))

        For nX := 1 to nUsado
            aColsEx[Len(aColsEx), nX] := SZJ->(FieldGet(FieldPos(aHeaderEx[nX, 2])))
        Next

        aColsEx[Len(aColsEx), nUsado + 1] := .F.
        SZJ->(DbSkip())
    End
Else
    //N=Ativos;M=Manutencao;P=Perdas;R=Ressarcidos;T=Em transito
    If !Empty(cArmazem)
        If cArmazem == "01"
            cStatus := "N"
        ElseIf cArmazem == "02"
            cStatus := "M"
        ElseIf cArmazem == "03"
            cStatus := "P"
        ElseIf cArmazem == "04"
            cStatus := "R"
        ElseIf cArmazem == "05"
            cStatus := "T"
        EndIf
    EndIf

    While SZJ->ZJ_FILIAL == xFilial("SZJ") .and.;
        SZJ->ZJ_CODPOST == cCodPosto .and.;
        SZJ->ZJ_LOCALID == cLocalid .and.;
        SZJ->ZJ_PRODUTO == SB1->B1_COD .and. !SZJ->(EOF())

        If lDisp .and. SZJ->ZJ_LOCADO == "S"
            SZJ->(DbSkip())
            Loop
        EndIf

        If !Empty(cArmazem)
            If SZJ->ZJ_LOCADO <> cStatus
                SZJ->(DbSkip())
                Loop
            EndIf
        EndIf

        Aadd(aColsEx, Array(nUsado + 1))

        For nX := 1 to nUsado
            aColsEx[Len(aColsEx), nX] := SZJ->(FieldGet(FieldPos(aHeaderEx[nX, 2])))
        Next

        aColsEx[Len(aColsEx), nUsado + 1] := .F.
        SZJ->(DbSkip())
    End
EndIf

DEFINE MSDIALOG oDlg TITLE "Patrimônio" FROM 000, 000  TO 500, 500 COLORS 0, 16777215 PIXEL

@ 005, 005 SAY oSay1 PROMPT AllTrim(SB1->B1_COD) SIZE 250, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 015, 005 SAY oSay2 PROMPT AllTrim(SB1->B1_DESC) SIZE 250, 007 OF oDlg COLORS 0, 16777215 PIXEL

oGet := MsNewGetDados():New( 025, 005, 227, 245, GD_INSERT+GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "",;
     aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeaderEx, aColsEx)

@ 233, 206 BUTTON oButton1 PROMPT "Fechar" ACTION(nOpcA := 0, oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

*/------------------------------------------------------------------*/
*/ Rotina: GravaEst													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Atualiza os saldos em estoque.                       			*/
*/------------------------------------------------------------------*/
User Function GravaEst(cCodPosto, cCodLoc, cProduto, cLocal, nQuant, cTipo)

Local lExiste   := .F.
Local nSaldoAtu := 0
Local nSaldoFim := 0
Default cTipo := "E"

SB1->(DbSetOrder(1)) // Código
SZF->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Local

SB1->(DbSeek(xFilial("SB1") + cProduto))

lExiste := SZF->(DbSeek(xFilial("SZF") + cCodPosto + cCodLoc + cProduto + cLocal))

If lExiste
    nSaldoAtu := SZF->ZF_SALDO
EndIf

// ------------------------------------------------------------------
// Somente aviso: movimento de saida que deixa o saldo negativo.
// Nao bloqueia a gravacao.
// ------------------------------------------------------------------
If cTipo == "S"
    nSaldoFim := nSaldoAtu - nQuant

    If nSaldoFim < 0
        MsgAlert("Atenção! Esta movimentação vai deixar o estoque negativo." + CRLF + ;
            "Posto avançado: " + AllTrim(cCodPosto) + CRLF + ;
            "Localidade....: " + AllTrim(cCodLoc) + CRLF + ;
            "Produto.......: " + AllTrim(cProduto) + " - " + AllTrim(SB1->B1_DESC) + CRLF + ;
            "Local.........: " + AllTrim(cLocal) + CRLF + ;
            "Saldo atual...: " + AllTrim(Transform(nSaldoAtu, "@E 999,999,999.99")) + CRLF + ;
            "Quantidade....: " + AllTrim(Transform(nQuant, "@E 999,999,999.99")) + CRLF + ;
            "Saldo final...: " + AllTrim(Transform(nSaldoFim, "@E 999,999,999.99")), "Estoque negativo")
    EndIf
EndIf

If !lExiste
    RecLock("SZF", .T.)
    SZF->ZF_FILIAL  := xFilial("SZF")
    SZF->ZF_CODPOST := cCodPosto
    SZF->ZF_LOCALID := cCodLoc
    SZF->ZF_PRODUTO := cProduto
    SZF->ZF_DESCRI  := SB1->B1_DESC
    SZF->ZF_LOCAL   := cLocal
    SZF->ZF_SALDO   := nQuant
    MsUnlock()
Else
    nSaldoAtu := If(cTipo=="E", SZF->ZF_SALDO + nQuant, SZF->ZF_SALDO - nQuant)

    RecLock("SZF", .F.)
    SZF->ZF_SALDO := nSaldoAtu
    MsUnlock()
EndIf

Return

*/------------------------------------------------------------------*/
*/ Rotina: TemPatrim												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Verifica se o produto controla patrimônio.              			*/
*/------------------------------------------------------------------*/
User Function TemPatrim(cProduto)

Local lControla := .F.

SB1->(DbSetOrder(1)) // Codigo

If SB1->(DbSeek(xFilial("SB1") + cProduto))
    If SB1->B1_XTPSB1 == "1"
        lControla := .T.
    EndIf
EndIf

Return(lControla)

*/------------------------------------------------------------------*/
*/ Rotina: LastItem 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Pega o último número de item usando no documento de locação.     */
*/------------------------------------------------------------------*/
User Function LastItem(cDocumento)

Local cLastItem := ""

SZI->(DbSetOrder(1)) // Documento + Item + Produto

SZI->(DbSeek(xFilial("SZI") + cDocumento))
While SZI->ZI_FILIAL == xFilial("SZI") .and.;
    SZI->ZI_DOC == cDocumento .and. !SZI->(EOF())

    If cLastItem < SZI->ZI_ITEM
        cLastItem := SZI->ZI_ITEM
    EndIf

    SZI->(DbSkip())
End

Return(cLastItem)

*/------------------------------------------------------------------*/
*/ Rotina: CanDelMov 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Verifica se pode deletar o documento de movimentos.              */
*/------------------------------------------------------------------*/
User Function CanDelMov(cDocumento)

Local lCanDel := .T.

BeginSQL Alias "Z42QRY"
    SELECT 
        ZI_ITEM
    FROM
        %Table:SZI%
    WHERE
        ZI_FILIAL = %xFilial:SZI% AND
        ZI_DOC = %Exp:cDocumento% AND
        ZI_STATUS <> 'A' AND
        %NotDel%
EndSQL

If !Z42QRY->(EOF())
    lCanDel := .F.
EndIf
Z42QRY->(DbCloseArea())

Return(lCanDel)

*/------------------------------------------------------------------*/
*/ Rotina: TemSubst 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Verifica se é um movimento ativo que substituiu outro.           */
*/------------------------------------------------------------------*/
User Function Temsubst(cDocumento)

Local lTemISSI := .F.

BeginSQL Alias "Z42QRY"
    SELECT 
        ZI_ITEM
    FROM
        %Table:SZI%
    WHERE
        ZI_FILIAL = %xFilial:SZI% AND
        ZI_DOC = %Exp:cDocumento% AND
        ZI_DOCSUBS = %Exp:cDocumento% AND
        %NotDel%
EndSQL

If !Z42QRY->(EOF())
    lTemISSI := .T.
EndIf
Z42QRY->(DbCloseArea())

Return(lTemISSI)

*/------------------------------------------------------------------*/
*/ Rotina: TemISSI   												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Verifica se tem rádio locado com a ISSI informada.               */
*/------------------------------------------------------------------*/
User Function TemISSI(cISSI)

Local lTemISSI := .F.

BeginSQL Alias "Z42QRY"
    SELECT 
        ZI_ISSI
    FROM
        %Table:SZI%
    WHERE
        ZI_FILIAL = %xFilial:SZI% AND
        ZI_ISSI = %Exp:cISSI% AND
        ZI_STATUS = "A" AND
        %NotDel%
EndSQL

If !Z42QRY->(EOF())
    lTemISSI := .T.
EndIf
Z42QRY->(DbCloseArea())

Return(lTemISSI)

*/------------------------------------------------------------------*/
*/ Rotina: RetLastQQP  												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna o número da última versão da QQP.                        */
*/------------------------------------------------------------------*/
User Function RetLastQQP(cProjeto)

Local cNumQQP := "0001"

BeginSQL Alias "Z42QRY"
    SELECT 
        MAX(Z42_NUMQQP) AS Z42_NUMQQP
    FROM
        %Table:Z42%
    WHERE
        Z42_FILIAL = %xFilial:Z42% AND
        Z42_PROJET = %Exp:cProjeto% AND
        %NotDel%
EndSQL

If !Z42QRY->(EOF())
    cNumQQP := Z42QRY->Z42_NUMQQP
EndIf
Z42QRY->(DbCloseArea())

Return(cNumQQP)
