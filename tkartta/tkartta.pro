; Tähtitieteen tutkimusprojekti I projektityö
; Tähtikartta
; Samppa Alatalo - 2503288
; Samppa.Alatalo@student.oulu.fi
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Aliohjelma syötteen pyytämiselle ja kelpaavan muodon
; tarkistamiselle. Aliohjelmaluonne mahdollistaa tarkistuksen
; toteutuksen, jossa annetun syote-muuttujan aliohjelman ulkopuolella
; määritetty luonne määrittää sen kelpaamisen syötteelle.
; Käytetty virheentarkistus perustuu IDL:n dokumentaation esimerkkiin:
; https://www.l3harrisgeospatial.com/docs/on_ioerror.html
PRO lue_syote,syote,syoteviesti=sv,virheviesti=vv,vertaus=vrt,vertailuvirhe=vrtv
  valid = 0                     ;oikeellisuuden ilmaisin
  viesti = ''                   ;syötettä pyydettäessä näytettävä viesti
  virhe = ''                    ;virheen sattuessa näytettävä viesti
  verrattava = ''               ;regex, johon syötettä verrataan
  vrtvirhe = ''                 ;viesti, joka näytetään, jos vertailu täsmää
  if keyword_set(sv) then viesti = string(sv)
  if keyword_set(vv) then virhe = string(vv)
  if keyword_set(vrt) then verrattava = string(vrt)
  if keyword_set(vrtv) then vrtvirhe = string(vrtv)
  
  while valid EQ 0 do begin
     on_ioerror,bad_input
     if keyword_set(sv) then read,syote,prompt=viesti $
     else read,syote
     if keyword_set(vrt) then begin
        syote_str = string(syote)
        if NOT syote_str.Matches(verrattava) then begin
           if keyword_set(vrtv) then print,vrtvirhe
           continue
        endif
     endif
     valid = 1
     bad_input: if ~ valid then begin
        if keyword_set(vv) then print,virhe $
        else continue
     endif
  endwhile
end

; Funktio tarkistaa onko annettu arvo ylärajan (yla) ja alarajan (ala)
; välissä ja palauttaa 1, jos näin on. Avainsanat salli_ala ja
; salli_yla sallivat vastaaville raja-arvoille osuvat arvot.
FUNCTION tarkista_raja,arvo,ala,yla,virheviesti,salli_ala=alaeq,salli_yla=ylaeq
  ; Suorita tarkistukset ja palauta tosi, jos jokin niistä toteutuu.
  if (arvo GT ala) AND (arvo LT yla) then return,1
  ; Jos jompi kumpi avainsana on annettu, tarkista rajatapaukset.
  if keyword_set(alaeq) AND (arvo EQ ala) then return,1
  if keyword_set(ylaeq) AND (arvo EQ yla) then return,1

  ; Jos mikään yllä ei toteudu, palauta epätosi ja virheviestit.
  print,virheviesti
  print,ala,yla,format='("Arvon on oltava väliltä ", F0.1, " - ", F0.1)'
  if keyword_set(alaeq) then print,'Alarajan arvo on sallittu.'
  if keyword_set(ylaeq) then print,'Ylärajan arvo on sallittu.'
  return,0
end

; Simppeli funktio kysyy vahvistusta jatkamiselle.
; Palauttaa totuusarvon vastauksen perusteella. Oletuksena 1.
FUNCTION kysy_jatko
  jatkovahvistus = ''
  read,jatkovahvistus,prompt='Jatketaanko ([y]/n)? '
  if jatkovahvistus.Contains('y',/FOLD_CASE) $
     OR jatkovahvistus.Contains('1',/FOLD_CASE) $
     OR jatkovahvistus.Contains('k',/FOLD_CASE) $
     OR jatkovahvistus EQ '' then return,1 $
  else return,0
end

;;; Pääohjelma alkaa

;;; Esittely
print,''
print,'Tervetuloa hienoon tähtikarttaan!'
print,'Tekijä: Samppa Alatalo'

;;; Datan lukeminen
print,'Valmistellaan dataa...'
n = file_lines('kirkkaat_tahdet.dat') - 3 ;kolme otsikkoriviä
ra = fltarr(n) & dec = ra & vmag = ra
openr,1,'kirkkaat_tahdet.dat'
otsikkoroskaa = ''
for i=0,2 do readf,1,otsikkoroskaa ;eroon tekstiriveistä
for i=0,n-1 do begin
   readf,1,rai,deci,vmagi
   ra(i) = rai
   dec(i) = deci
   vmag(i) = vmagi
endfor
close,1
print,'Data OK'
; print,min(vmag),max(vmag),format='("Magnitudiväli: ",F0," - ",F0)'
print,''

;;; Koordinaattivälien hankkiminen
while 1 do begin
   
   ra_ala = 0.
   ra_yla = 0.
   dec_ala = 0.
   dec_yla = 0.
   
   print,'Anna haluamasi alue tähtikartalta koordinaattien avulla asteina.'
   
   ; Virheviestit
   numvirhe = 'Arvo on annettava numerona.'
   rajavirhe = 'Arvo on sallittujen rajojen ulkopuolella!'
   
   ; Rektaskension alaraja
   valid = 0                    ;oikeellisuuden ilmaisin
   while valid EQ 0 do begin
      lue_syote,ra_ala,syoteviesti='Anna rektaskension alaraja: ',virheviesti=numvirhe
      if NOT tarkista_raja(ra_ala,0.,360.,rajavirhe,/salli_ala) then continue
      valid = 1
   endwhile
   
   ; Rektaskension yläraja
   valid = 0
   while valid EQ 0 do begin
      lue_syote,ra_yla,syoteviesti='Anna rektaskension yläraja: ',virheviesti=numvirhe
      if NOT tarkista_raja(ra_yla,ra_ala,360.,rajavirhe,/salli_yla) then continue
      valid = 1
   endwhile
   
   ; Deklinaation alaraja
   valid = 0
   while valid EQ 0 do begin
      lue_syote,dec_ala,syoteviesti='Anna deklinaation alaraja: ',virheviesti=numvirhe
      if NOT tarkista_raja(dec_ala,-90.,90.,rajavirhe,/salli_ala) then continue
      valid = 1
   endwhile
   
   ; Deklinaation yläraja
   valid = 0
   while valid EQ 0 do begin
      lue_syote,dec_yla,syoteviesti='Anna deklinaation yläraja: ',virheviesti=numvirhe
      if NOT tarkista_raja(dec_yla,dec_ala,90.,rajavirhe,/salli_yla) then continue
      valid = 1
   endwhile

   ; Käyttömukavuutta lisäävä tuloste ja jatkamisen vahvistus
   print,''
   print,ra_ala,ra_yla,format='("Valittu rektaskensioväli: ",F0.2," - ",F0.2)'
   print,dec_ala,dec_yla,format='("Valittu deklinaatioväli: ",F0.2," - ",F0.2)'
   if kysy_jatko() then break else print,'Otetaan alusta...'
   print,''
   
endwhile
print,''

;;; Halutun ajan hankkiminen
while 1 do begin
   
   aika = ''
   ; Syötteen kelpaamisen tarkistukseen käytettävä regular expression -merkkijono
   vrt = '^ *[Jj][0-9]+\.?([0-9]+)? *$|^ *(([0-2]?[1-9])|(3[01]))\.((0?[1-9])|(1[0-2]))\.-?'
   vrt += '((0*[1-9])|([1-9][0-9]+))( (([0-1]?[0-9])|(2[0-3]))[:.]([0-5]?[0-9])([:.]([0-5]?[0-9]))?)? *$'
   
   print,'Anna haluamasi ajankohta joko juliaanisena tai gregoriaanisena muodossa'
   print,'"JXXXX(.X)" tai "DD.MM.YYYY( HH:MM:SS)" vastaavasti.'
   print,'Suluilla merkityt osat ovat vapaaehtoisia.'
   print,'Kellonaika tulkitaan universaalina aikana (UT).'

   ; Luetaan käyttäjän syöte aikamuuttujaan ja tarkistetaan
   lue_syote,aika,syoteviesti='Anna ajankohta: ',virheviesti='Syöte ei kelpaa!',$
             vertaus=vrt,vertailuvirhe='Ajankohdan muoto ei kelpaa!'
   aika = aika.Trim() ;mahd. ylimääräiset välit pois
   
   if NOT aika.StartsWith('J',/FOLD_CASE) then begin
      pvm = aika                ;syöte talteen myöhempään käyttöön
      greg = fix(aika.Split('[ .:]') ) ;päiväyksen osien erottelu
      ; Jos vapaaehtoisia ei ole täytetty, täydennetään
      if n_elements(greg) LT 6 then greg = [greg,intarr(6-n_elements(greg) ) ]
      ; Muunnetaan juliaaniseksi
      aika = julday(greg(1),greg(0),greg(2),greg(3),greg(4),greg(5) )
   endif else aika = double(aika.Remove(0,0) ) ;muutoin vain poistetaan 'J'
   aika_prnt = string(aika,format='("J",F0.1)') ;printtiystävällinen aikamuuttuja
   
   ; Jälleen käyttömukavuutta
   print,''
   print,aika_prnt,format='("Valittu ajankohta: ",A)'
   if kysy_jatko() then break else print,'Otetaan alusta...'
   print,''
   
endwhile
print,''

;;; Tähtien sijaintien laskeminen
ra_eq2 = ra & dec_eq2 = dec
if aika NE 2000. then precess,ra_eq2,dec_eq2,2000,aika
print,'Tähtien sijainnit laskettu.'

; Koordinaattivälit
inds = where(ra_eq2 GE ra_ala AND ra_eq2 LE ra_yla $
             AND dec_eq2 GE dec_ala AND dec_eq2 LE dec_yla)
ra_vali = ra_eq2(inds)
dec_vali = dec_eq2(inds)
vmag_vali = vmag(inds)
print,'Koordinaattialue määritetty.'

; Magnitudien ryhmittely
; Käytetyn datasetin magnitudiväli on -1.46 - 7.96.
; Toteutus perustuu IDL-harjoitustyöhön.
vmag_i = list()
for i=0,8 do begin
   ; Alkuun erotetaan tapaus <-1
   if i EQ 0 then vmag_i.add,[where(vmag_vali LT float(i-1),/NULL)] $
   else begin
      ; Lisätään magnitudit yhden magnitudin välein
      vmag_i.add,[where(vmag_vali GE float(i-2)$
                        AND vmag_vali LT float(i-1),/NULL)]
   endelse
endfor
; Lisätään vielä tapaus >7
vmag_i.add,[where(vmag_vali GE 7.,/NULL)]

;;; Kartan piirtäminen
psopen,'./tahtikartta.ps',/color
nwin
vmag_koko = vmag_i.count() - 1  ;silmukkamuuttujan yläraja
pos = [0.1,0.1,0.75,0.9]        ;arvo plot-komennon position-avainsanalle
syms = 4.                       ;symsize-avainsanan alkuarvo
color = indgen(vmag_koko+2)     ;color-avainsanan arvotaulukko
remove,1,color                  ;poistetaan musta väri (1)
; Selitteen nimilista ja alkusijainti
selite = ['<-1','-1<0','0<1','1<2','2<3','3<4','4<5','5<6','6<7','>7']
selite_x = pos(2) + 0.05
selite_y = pos(3) - 0.05
nimi_x = selite_x + 0.03

; Kartan alustus
plot,[0,1],[0,1],/NODATA,title='Kartta '+aika_prnt,$
     xtitle=textoidl('Rektaskensio \alpha (deg)'),$
     ytitle=textoidl('Deklinaatio \delta (deg)'),$
     xr=[max(ra_vali),min(ra_vali)],yr=[min(dec_vali),max(dec_vali)],$
     position=pos,xs=1,ys=1,psym=2,symsize=syms,color=color(0)

; Plottaus
for i=0,vmag_koko do begin
   if vmag_i(i) NE !NULL then begin
      oplot,ra_vali(vmag_i(i) ),dec_vali(vmag_i(i) ),$
            psym=2,symsize=syms,color=color(i)
   endif
   plots,selite_x,selite_y-i/20.,psym=2,symsize=syms,color=color(i),/normal
   xyouts,nimi_x,selite_y-i/20.,selite(i),/normal
   syms -= 0.4
endfor
psclose

print,'Kartan piirtäminen valmis.'
print,'tahtikartta.ps luotu.'
print,''
print,'Kiitos tähtikarttaohjelman käytöstä!'
print,''

end
