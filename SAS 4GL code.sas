libname projekt1 'C:\Users\adria\Desktop\';

%let bib =projekt1;
%let zbior =beeps;

/*ograniczenie zbioru danych celem wyodrêbnienia zmiennej celu oraz zmiennych objaœniaj¹cych*/
data &bib..danePROJEKT (keep=  a1 d2 a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b );
set &bib..&zbior.;
run; 

/*Wybrane do badania zosta³y kraje strefy EURO i Polska*/
data &bib..danePROJEKT;
set &bib..danePROJEKT;
where a1 in (59 72 76 77 79 90 300);
run;

/*Odrzucenie odpowiedzi don't know i refusal jako braków danych*/
data dane;
set &bib..danePROJEKT;
if a3 <0 then delete;
else if a6b <0 then delete;
else if b6b <0 then delete;
else if b7 <0 then delete;
else if b8 <0 then delete;
else if H1 <0 then delete;
else if H5 <0 then delete; 
else if H6 <0 then delete;
else if k3bc <0 then delete;
else if e2b <0 then delete;  
run;

/* Zamiana odpowiedzi don't know i refusal zmiennej celu na braki danych*/
data dane;
set dane;
if d2=-8 or d2=-9 then d2a=null;
else d2a=d2;
drop d2 null;
rename d2a=d2;
run;

/*Przeliczenie waluty PLN na EURO 4.1925 dla obserwacji z Polski*/
data dane;
set work.dane;
if a1=59 then d2a=d2/4.1925;
else d2a=d2;
drop d2;
rename d2a=d2;
run;

/*Badanie wspó³liniowoœci - statystyka VIF*/
ods listing gpath= 'C:\Users\adria\Desktop\';
ods graphics / imagename="Proc Reg 1" imagefmt=png;
proc reg data=dane;
model d2 = a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b / vif ;
run;

/*Usuniêcie obserwacji odstaj¹cych z d2*/
proc sql;
create table dane1 as
select *
from work.dane
where d2 < 25000000
order by d2 desc;
quit;

/*Usuniêcie obserwacji odstaj¹cych z b6b*/
proc sql;
create table dane2 as
select *
from work.dane1
where b6b > 1949
order by b6b;
quit;
/*Podstawowe statystyki wyselekcjonowanych zmiennych w finalnym zbiorze danych*/ 
proc means data=work.dane n mean median std skewness kurtosis min max;
run;

/*Ponowne badanie wspó³liniowoœci - statystyka VIF*/
ods listing gpath= 'C:\Users\adria\Desktop\';
ods graphics / imagename="Proc Reg 2" imagefmt=png;
proc reg data=dane2;
model d2 = a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b / vif ;
run;

/*Przeskalowanie zmiennej d2 przez 1 000 000*/
data &bib..dane_FINAL (drop=a1);
set work.dane2;
d2= d2/1000000;
run;

/*Zbadanie rozk³adu zmiennej celu*/
ods listing gpath= 'C:\Users\adria\Desktop\';
ods graphics / imagename="Proc UNIV" imagefmt=png;
PROC UNIVARIATE DATA = &bib..dane_FINAL;
	VAR d2;
	HISTOGRAM   d2 / NORMAL;
	HISTOGRAM   d2/ GAMMA;
RUN;

/**/
/*		Analiza w³aœciwa*/
/**/

/*Zapis wyników w postaci tabel do pliku excel*/
ODS TAGSETS.EXCELXP
file='C:\Users\adria\Desktop\ProcMi1.xls\'
STYLE=minimal
OPTIONS ( Orientation = 'landscape'
FitToPage = 'yes'
Pages_FitWidth = '1'
Pages_FitHeight = '100' );

/*Budowa modelu z brakami danych*/
proc genmod  data=&bib..dane_FINAL;
class a3 a6b b8 H1 H5 H6;
model d2 = a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b / 
 dist=gamma type3;
run;

/*Sprawdzenie wzoru braku danych*/
proc mi data=&bib..dane_FINAL  nimpute=20 out=ProcMi1 seed=2020 ;
var d2 a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b;
run;

/*Wykonanie imputacji*/
proc mi data=&bib..dane_FINAL seed=2020 nimpute=20 out=&bib..dane_IMPUT;
   class a3 a6b b8 H1 H5 H6;
   fcs
       reg(d2= a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b /details );
   var d2 a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b;
run;

/*Budowa modelu po imputacji, bez braków danych*/
proc genmod  data=&bib..dane_IMPUT;
class a3 (PARAM=REF) a6b (PARAM=REF) b8 (PARAM=REF) H1 (PARAM=REF) H5 (PARAM=REF) H6 (PARAM=REF);
model d2 = a3 a6b b6b b7 b8 H1 H5 H6 k3bc e2b / 
 dist=gamma type1 type3 covb  ;
by _Imputacja_;
ods output CovB=mixcovb ;
run;

/*mianalyze dla modelu z imputacj¹ */
proc mianalyze data=&bib..dane_IMPUT ;
  	modeleffects  a3 a6b b7 b8 H6 e2b;
	stderr  a3 a6b b7 b8 H6 e2b;
run;



/* Kod do wykresów z Pythona*/


/* plt.figure(figsize=(20, 18))

subplot(3,2,1)

ax=sns.countplot(x = "a3", data = data, palette="ocean")
ax.set_title("City population", fontsize = 20)
plt.xlabel("a3", fontsize=15)
plt.ylabel("count", fontsize=15)
for p in ax.patches:
    ax.annotate(f'\n{p.get_height()}', (p.get_x()+0.2, p.get_height()), ha='center', va='top', color='white', size=18)
    
subplot(3,2,2)

ax=sns.countplot(x = "a6b", data = data, palette="ocean")
ax.set_title("Screener size", fontsize = 20)
plt.xlabel("a6b", fontsize=15)
plt.ylabel("count", fontsize=15)
for p in ax.patches:
    ax.annotate(f'\n{p.get_height()}', (p.get_x()+0.2, p.get_height()), color='black', size=15, ha="center")

subplot(3,2,3)

ax=sns.countplot(x = "b8", data = data, palette="ocean")
ax.set_title("Internationally-recognized quality certification", fontsize = 20)
plt.xlabel("b8", fontsize=15)
plt.ylabel("count", fontsize=15)
for p in ax.patches:
    ax.annotate(f'\n{p.get_height()}', (p.get_x()+0.2, p.get_height()), ha='center', va='top', color='white', size=18)
    
subplot(3,2,4)

ax=sns.countplot(x = "h1", data = data, palette="ocean")
ax.set_title("New products/services introduced in the last 3 years", fontsize = 20)
plt.xlabel("h1", fontsize=15)
plt.ylabel("count", fontsize=15)
for p in ax.patches:
    ax.annotate(f'\n{p.get_height()}', (p.get_x()+0.2, p.get_height()), ha='center', va='top', color='white', size=18)
    
subplot(3,2,5)

ax=sns.countplot(x = "h5", data = data, palette="ocean")
ax.set_title("New marketing methods introduced over lats 3 years", fontsize = 20)
plt.xlabel("h5", fontsize=15)
plt.ylabel("count", fontsize=15)
for p in ax.patches:
    ax.annotate(f'\n{p.get_height()}', (p.get_x()+0.2, p.get_height()), ha='center', va='top', color='white', size=18)
    
subplot(3,2,6)

ax=sns.countplot(x = "h6", data = data, palette="ocean")
ax.set_title("R&D expenditure over the last 3 years", fontsize = 20)
plt.xlabel("h6", fontsize=15)
plt.ylabel("count", fontsize=15)
for p in ax.patches:
    ax.annotate(f'\n{p.get_height()}', (p.get_x()+0.2, p.get_height()), color='black', size=15, ha="center")
*/