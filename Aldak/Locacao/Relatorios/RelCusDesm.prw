#include "protheus.ch"

*/------------------------------------------------------------------*/
*/ Rotina: RelcusDesm												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/12/2025												*/
*/------------------------------------------------------------------*/
*/ Relatório de custos Desmmbrados.                            		*/
*/------------------------------------------------------------------*/
User Function RelcusDesm()
      
Local aCustos := {}

// Posto de
// Posto ate
// Localidade de
// Localidade ate
// Dia de corte
// Período de
// Período ate
If !Pergunte("RELAPRCUST", .T.)
	Return
EndIf

MsgRun("Aguarde, carregando movimentos...",, {|| ProcRel(@aCustos)})
MsgRun("Aguarde, carregando planilha Excel...",, {|| GeraExcel(aCustos)})

Return            

*/------------------------------------------------------------------*/
*/ Rotina: ProcRel  												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/12/2025												*/
*/------------------------------------------------------------------*/
*/ Processamentos do Relatório.                                		*/
*/------------------------------------------------------------------*/
Static Function ProcRel(aCustos)

Local nX         := 0
Local nPos       := 0
Local nValorBase := 0
Local nValorUnit := 0
Local nTotRadio  := 0
Local nTotRadLoc := 0
Local cDescRadio := ""
Local cDescPost  := ""
Local cDescLocal := ""
Local dDataCorte := CtoD(StrZero(mv_par05, 2) + "/" + StrZero(Month(dDatabase), 2) + "/" + AllTrim(Str(Year(dDataBase))))
Local aNiveisCC  := {}
Local aMovimento := {}

SB1->(DbSetOrder(1)) // Codigo
SZ1->(DbSetOrder(1)) // Cod.posto
SZ2->(DbSetOrder(1)) // Cod.posto + Localidade
SZK->(DbSetOrder(1)) // Cliente + Loja + Patromônio
SZN->(DbSetOrder(1)) // Cód.posto + Projeto + Num QQP + Item

BeginSQL Alias "SZIQRY"
SELECT
	ZI_PRODUTO, ZI_PATRIM, ZI_QUANT, ZI_DATAMOV, ZI_DATADEV, ZI_CODKIT, ZH_CODPOST, ZH_LOCALID, ZH_CC
FROM
	%Table:SZI% SZI
	INNER JOIN %Table:SZH% SZH ON ZH_DOC = ZI_DOC
	INNER JOIN %Table:SZ1% SZ1 ON Z1_CODPOST = ZH_CODPOST
	INNER JOIN %Table:SZ2% SZ2 ON Z2_LOCALID = ZH_LOCALID
WHERE
	ZI_FILIAL = %xFilial:SZI% AND
	ZH_FILIAL = %xFilial:SZH% AND
	Z1_FILIAL = %xFilial:SZ1% AND
	Z2_FILIAL = %xFilial:SZ2% AND
	ZH_CODPOST BETWEEN %Exp:mv_par01% AND %Exp:mv_par02% AND
	ZH_LOCALID BETWEEN %Exp:mv_par03% AND %Exp:mv_par04% AND
	ZI_STATUS IN ('A', 'D') AND
	ZI_PATRIM <> '' AND
	(ZI_DATADEV >= %Exp:DtoS(mv_par06)% AND ZI_DATADEV <= %Exp:DtoS(mv_par07)% OR ZI_DATADEV = '') AND
	SZI.%NotDel% AND
	SZH.%NotDel% AND
	SZ1.%NotDel% AND
	SZ2.%NotDel%
	ORDER BY ZH_LOCALID, ZH_CC, ZI_PRODUTO
EndSQL
    
aNiveisCC := U_RetNivelCC(SZIQRY->ZH_CC)

// aMovimento[1] - Posto avançado
// aMovimento[2] - Localidade
// aMovimento[3] - Centro de Custo
// aMovimento[4] - Produto
// aMovimento[5] - Quantidade
// aMovimento[6] - Patrimonio
// aMovimento[7] - Data da Entrega
// aMovimento[8] - Data da devolução
// aMovimento[9] - Kit

While !SZIQRY->(EOF())
    aNiveisCC := U_RetNivelCC(SZH->ZH_CC)

    aAdd(aMovimento, {;
        SZIQRY->ZH_CODPOST,;
        SZIQRY->ZH_LOCALID,;
        SZIQRY->ZH_CC,;
        SZIQRY->ZI_PRODUTO,;
        SZIQRY->ZI_QUANT,;
        SZIQRY->ZI_PATRIM,;
        StoD(SZIQRY->ZI_DATAMOV),;
        StoD(SZIQRY->ZI_DATADEV),;
        })
	SZIQRY->(DbSkip())
End
SZIQRY->(DbCloseArea())

//Carrega o custo dos equipamentos / patrimônios.
// aCustos[1] - Código do Posto avançado
// aCustos[2] - Posto avançado
// aCustos[3] - Código da Localidade
// aCustos[4] - Localidade
// aCustos[5] - Diretoria
// aCustos[6] - Gerência geral
// aCustos[7] - Gerância de área
// aCustos[8] - Centro de custo
// aCustos[9] - Produto
// aCustos[10] - Descrição / Rádio
// aCustos[11] - Valor Base
// aCustos[12] - Quantidade
// aCustos[12] - Valor Unitário
// aCustos[14] - Total
// aCustos[14] - Tipo

For nX := 1 to Len(aMovimento)
    aNiveisCC := U_RetNivelCC(aMovimento[nX, 3])

    cDescRadio := ""
    If SB1->(DbSeek(xFilial("SB1") + aMovimento[nX, 4]))
        cDescRadio := AllTrim(SB1->B1_DESC)
    EndIf

    cDescPost := ""
    If SZ1->(DbSeek(xFilial("SZ1") + aMovimento[nX, 1]))
        cDescPost := AllTrim(SZ1->Z1_DESCRI)
    EndIf

    nValorBase := 0
    cDescLocal := ""
    If SZ2->(DbSeek(xFilial("SZ2") + aMovimento[nX, 2]))
        cDescLocal := AllTrim(SZ2->Z2_DESCRI)
    EndIf

    If SZK->(DbSeek(xFilial("SZK") + aMovimento[nX, 1] + aMovimento[nX, 2] + aMovimento[nX, 9] + aMovimento[nX, 6]))
        // Se o equipamento foi entregue na segunda quimzena dp fechamento não tem cobrança.
        // Para isso basta vermos se a entrega foi antes da data de corte.
        If aMovimento[nX, 7] < dDataCorte
            nValorBase := SZK->ZK_VALOR
        EndIf

        // Se é a primeira locação e está dentro da primeira quinzena e dentro do período de corte teria cobrança, 
        // mas como é a primeira locação o equipamento deve aparecer no primeiro fechamento com valor zero.
        If aMovimento[nX, 7] == SZK->ZK_ENTREGA
            nValor := 0
        EndIf
    EndIf

    aAdd(aCustos, {;
        aMovimento[nX, 1],;
        cDescPost,;
        aMovimento[nX, 2],;
        cDescLocal,;
        aNiveisCC[1, 2],;
        aNiveisCC[2, 2],;
        aNiveisCC[3, 2],;
        aMovimento[nX, 3],;
        aMovimento[nX, 4],;
        cDescRadio,;
        nValorBase,;
        aMovimento[nX, 5],;
        nValorBase,;
        nValorBase * aMovimento[nX, 5],;
        "R",;
    })

    // Carrega os custos da infra rateados.
    nTotRadio := TotRadios(aMovimento[nx, 1], mv_par06)

    If SZN->(DbSeek(xFilial("SZN") + aMovimento[nX, 1]))
        aNiveisCC := U_RetNivelCC(aMovimento[nX, 3])

        While SZN->ZN_FILIAL == xFilial("SZN") .and.;
            SZN->ZN_CODPOST == aMovimento[nX, 1] .and. SZN->(!EOF())

            cDescPost := ""
            If SZ1->(DbSeek(xFilial("SZ1") + aMovimento[nX, 1]))
                cDescPost := AllTrim(SZ1->Z1_DESCRI)
            EndIf

            nValorBase := 0
            cDescLocal := ""
            If SZ2->(DbSeek(xFilial("SZ2") + aMovimento[nX, 2]))
                cDescLocal := AllTrim(SZ2->Z2_DESCRI)
            EndIf

            nTotRadLoc := 0
            nPos := Ascan(aCustos, {|x| x[1] == aMovimento[nX, 1] .and. x[3] == aMovimento[nX, 2] .and.;
                x[8] == aMovimento[nX, 3] .and. x[9] == aMovimento[nX, 4]})
            If nPos > 0
                nTotRadLoc := aCustos[nPos, 12]
            EndIf

            nValorUnit := (nTotRadLoc / nTotRadio) * SZN->ZN_VALOR

            aAdd(aCustos, {;
                aMovimento[nX, 1],;
                cDescPost,;
                aMovimento[nX, 2],;
                cDescLocal,;
                aNiveisCC[1, 2],;
                aNiveisCC[2, 2],;
                aNiveisCC[3, 2],;
                aMovimento[nX, 3],;
                "",;
                SZN->ZN_DESCRI,;
                0,;
                nTotRadLoc / nTotRadio,;
                nValorUnit,;
                SZN->ZN_QUANT * nValorUnit,;
                "I",;
            })
            SZN->(DbSkip())
        End
    EndIf
Next nX

Return

*/------------------------------------------------------------------*/
*/ Rotina: GeraExcel												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/12/2025												*/
*/------------------------------------------------------------------*/
*/ Geração do relatório em Excel.                              		*/
*/------------------------------------------------------------------*/
Static Function GeraExcel(aCustos)

Local nX		:= 0
Local oExcel    := FWMSExcel():New()
Local cDirDocs  := MsDocPath()
Local cPath		:= AllTrim(GetTempPath())

oExcel:AddworkSheet("Custos")
oExcel:AddTable ("Custos","Locação")

// aCustos[1] - Código do Posto avançado
// aCustos[2] - Posto avançado
// aCustos[3] - Código da Localidade
// aCustos[4] - Localidade
// aCustos[5] - Diretoria
// aCustos[6] - Gerência geral
// aCustos[7] - Gerância de área
// aCustos[8] - Centro de custo
// aCustos[9] - Produto
// aCustos[10] - Descrição / Rádio
// aCustos[11] - Valor Base
// aCustos[12] - Quantidade
// aCustos[12] - Valor Unitário
// aCustos[14] - Total
// aCustos[15] - Tipo

oExcel:AddColumn("Custos","Locação","Posto avançado",1,1,.F.)
oExcel:AddColumn("Custos","Locação","Localidade",1,1,.F.)
oExcel:AddColumn("Custos","Locação","Diretoria",1,1,.F.)
oExcel:AddColumn("Custos","Locação","Gerência Geral",1,1,.F.)
oExcel:AddColumn("Custos","Locação","Gerência de Área",1,1,.F.)
oExcel:AddColumn("Custos","Locação","Centro de Custo",1,1,.F.)
oExcel:AddColumn("Custos","Locação","Descrição / Rádio",1,1,.F.)
oExcel:AddColumn("Custos","Locação","Valor Base",3,1,.F.)	
oExcel:AddColumn("Custos","Locação","Quantidade",3,1,.F.)	
oExcel:AddColumn("Custos","Locação","Valor Unitário",3,1,.F.)	
oExcel:AddColumn("Custos","Locação","Total",3,1,.F.)	
		
For nX := 1 to Len(aCustos)
    oExcel:AddRow("Custos","Locação",{;
        aCustos[nX, 2],;
        aCustos[nX, 4],;
        aCustos[nX, 5],;
        aCustos[nX, 6],;
        aCustos[nX, 7],;
        aCustos[nX, 8],;
        aCustos[nX, 10],;
        aCustos[nX, 11],;
        aCustos[nX, 12],;
        aCustos[nX, 13],;
        aCustos[nX, 14]})
Next nX

oExcel:Activate()

oExcel:GetXMLFile(cDirDocs+"\Custos.xml")

CpyS2T(cDirDocs+"\Custos.xml" , cPath, .T.)

If !ApOleClient("MsExcel")
	MsgAlert("MsExcel não instalado.")
	Return
EndIf

oExcelApp := MsExcel():New()
oExcelApp:WorkBooks:Open(cPath+"Custos.xml")
oExcelApp:SetVisible(.T.)

Return

*/------------------------------------------------------------------*/
*/ Rotina: TotRadios												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/12/2025												*/
*/------------------------------------------------------------------*/
*/ Retorna a quantidade de rádios ativos no posto avançado.			*/
*/------------------------------------------------------------------*/
Static Function TotRadios(cCodPosto, dDtFecham)

Local nQuant := 0

BeginSQL Alias "SZIQRY"
SELECT
	COUNT(ZI_QUANT) AS ZI_QANT
FROM
	%Table:SZI% SZI
	INNER JOIN %Table:SZH% SZH ON ZH_DOC = ZI_DOC
WHERE
	ZI_FILIAL = %xFilial:SZI% AND
	ZH_FILIAL = %xFilial:SZH% AND
	ZH_CODPOST = %Exp:cCodPosto% AND
	ZI_STATUS IN ('A', 'D') AND
	ZI_PATRIM <> '' AND
	(ZI_DATADEV >= %Exp:DtoS(mv_par06)% AND ZI_DATADEV <= %Exp:DtoS(mv_par07)% OR ZI_DATADEV = '') AND
	SZI.%NotDel% AND
	SZH.%NotDel%
EndSQL

If !SZIQRY->(EOF())
    nQuant := SZIQRY->ZI_QANT
EndIf
SZIQRY->(DbCloseArea())

Return(nQuant)
