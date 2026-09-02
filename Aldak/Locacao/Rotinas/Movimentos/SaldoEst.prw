#include "totvs.ch"
*/------------------------------------------------------------------*/
*/ Rotina: SaldoEst													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Saldos de Estoque por Posto avançado.							*/
*/------------------------------------------------------------------*/
User Function SaldoEst()

Private cCadastro := "Saldos em Estoque"
Private aRotina   := {}					 

aAdd(aRotina ,{"Pesquisar" 		, "AxPesqui"                   , 0, 1})
aAdd(aRotina ,{"Visualizar"		, 'AxVisual'				   , 0, 2})
aAdd(aRotina ,{"Patrimonios"	, 'U_PesqPat(SZF->ZF_CODPOST, SZF->ZF_LOCALID, SZF->ZF_PRODUTO,,,,SZF->ZF_LOCAL)'  , 0, 5})

MBrowse(006, 001, 022, 075, "SZF")

Return
