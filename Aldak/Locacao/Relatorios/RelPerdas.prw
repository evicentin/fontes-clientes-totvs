#include "protheus.ch"

User Function RelPerdas()
      
Local aPerdas := {}

If !Pergunte("RELPERDAEQ", .T.)
	Return
EndIf

MsgRun("Aguarde, carregando perdas...",, {|| ProcRel(@aPerdas)})
MsgRun("Aguarde, carregando planilha Excel...",, {|| GeraExcel(aPerdas)})

Return            

Static Function ProcRel(aPerdas)
                   
//aPerdas[1] - Posto Avançado
//aPerdas[2] - Localidade
//aPerdas[3] - Data
//aPerdas[4] - Produto
//aPerdas[5] - Descrição
//aPerdas[6] - Patrimônio
//aPerdas[7] - Núm.Série
//aPerdas[8] - Quantidade
//aPerdas[9] - Responsável
//aPerdas[10] - Diretoria
//aPerdas[11] - Gerência Geral
//aPerdas[12] - Gerência de Área
//aPerdas[13] - Coordenação
//aPerdas[14] - Supervisão

SB1->(DbSetOrder(1))

BeginSQL Alias "SZMQRY"
SELECT
    ZM_CODPOST, ZM_LOCALID, ZM_DOC, ZM_DATA, ZM_PRODUTO, ZM_PATRIM, ZM_NUMSER, ZM_QUANT, ZH_LOCALID, ZH_CODRESP, ZH_CC, Z1_DESCRI, Z2_DESCRI, Z0_NOME
FROM
    %Table:SZM% SZM
	INNER JOIN %Table:SZH% SZH ON ZH_DOC = ZM_DOC
	INNER JOIN %Table:SZ1% SZ1 ON Z1_CODPOST = ZM_CODPOST
	INNER JOIN %Table:SZ2% SZ2 ON Z2_LOCALID = ZM_LOCALID
	INNER JOIN %Table:SZ0% SZ0 ON Z0_CODRESP = ZH_CODRESP
WHERE
	ZM_FILIAL = %xFilial:SZM% AND
	ZH_FILIAL = %xFilial:SZH% AND
	Z2_FILIAL = %xFilial:SZ2% AND
	Z0_FILIAL = %xFilial:SZ0% AND
    ZM_CODPOST BETWEEN %Exp:mv_par01% AND %Exp:mv_par02% AND
    ZM_LOCALID BETWEEN %Exp:mv_par03% AND %Exp:mv_par04% AND
    ZM_DATA BETWEEN %Exp:DtoS(mv_par05)% AND %Exp:DtoS(mv_par06)% AND
	SZM.%NotDel% AND
	SZH.%NotDel% AND
	SZ1.%NotDel% AND
	SZ2.%NotDel% AND
	SZ0.%NotDel%
ORDER BY ZM_CODPOST, ZM_LOCALID, ZM_DATA, ZM_DOC, ZM_ITEM
EndSQL
    
aNiveisCC := U_RetNivelCC(SZMQRY->ZH_CC)

While !SZMQRY->(EOF())
    SB1->(DbSeek(xFilial("SB1") + SZMQRY->ZM_PRODUTO))
	aAdd(aPerdas, {;
		SZMQRY->Z1_DESCRI,;
		SZMQRY->Z2_DESCRI,;
		StoD(SZMQRY->ZM_DATA),;
		SZMQRY->ZM_PRODUTO,;
		AllTrim(SB1->B1_DESC),;
		SZMQRY->ZM_PATRIM,;
		SZMQRY->ZM_NUMSER,;
		SZMQRY->ZM_QUANT,;
		SZMQRY->Z0_NOME,;
		aNiveisCC[1, 2],;
		aNiveisCC[2, 2],;
		aNiveisCC[3, 2],;
		aNiveisCC[4, 2],;
		aNiveisCC[5, 2],;
		})
	SZMQRY->(DbSkip())
End
SZMQRY->(DbCloseArea())

Return

Static Function GeraExcel(aPerdas)

Local nX		    := 0
Local oExcel    := FWMSEXCEL():New()
Local cDirDocs  := MsDocPath()
Local cPath		:= AllTrim(GetTempPath())

oExcel:AddworkSheet("Equipamentos")
oExcel:AddTable ("Equipamentos","Perdas")

//aPerdas[1] - Posto Avançado
//aPerdas[2] - Localidade
//aPerdas[3] - Data
//aPerdas[4] - Produto
//aPerdas[5] - Descrição
//aPerdas[6] - Patrimônio
//aPerdas[7] - Núm.Série
//aPerdas[8] - Quantidade
//aPerdas[9] - Responsável
//aPerdas[10] - Diretoria
//aPerdas[11] - Gerência Geral
//aPerdas[12] - Gerência de Área
//aPerdas[13] - Coordenação
//aPerdas[14] - Supervisão

oExcel:AddColumn("Equipamentos","Perdas","Posto Avançado",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Localidade",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Data",1,4,.F.)	
oExcel:AddColumn("Equipamentos","Perdas","Produto",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Descrição",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Patrimônio",1,1,.F.)	
oExcel:AddColumn("Equipamentos","Perdas","Num.Série",1,1,.F.)	
oExcel:AddColumn("Equipamentos","Perdas","Quantidade",3,1,.F.)	
oExcel:AddColumn("Equipamentos","Perdas","Responsável",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Diretoria",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Gerência Geral",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Gerência de Área",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Coordenação",1,1,.F.)
oExcel:AddColumn("Equipamentos","Perdas","Supervisão",1,1,.F.)
		
For nX := 1 to Len(aPerdas)
	oExcel:AddRow("Equipamentos","Perdas",{;
		aPerdas[nX,1],;
		aPerdas[nX,2],;
		aPerdas[nX,3],;
		aPerdas[nX,4],;
		aPerdas[nX,5],;
		aPerdas[nX,6],;
		aPerdas[nX,7],;
		aPerdas[nX,8],;
		aPerdas[nX,9],;
		aPerdas[nX,10],;
		aPerdas[nX,11],;
		aPerdas[nX,12],;
		aPerdas[nX,13],;
		aPerdas[nX,14]})
Next nX

oExcel:Activate()

oExcel:GetXMLFile(cDirDocs+"\Perdas.xml")

CpyS2T(cDirDocs+"\Perdas.xml" , cPath, .T.)

If !ApOleClient("MsExcel")
	MsgAlert("MsExcel não instalado.")
	Return
EndIf

oExcelApp := MsExcel():New()
oExcelApp:WorkBooks:Open(cPath+"Perdas.xml")
oExcelApp:SetVisible(.T.)

Return
