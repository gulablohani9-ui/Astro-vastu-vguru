// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jyotish/jyotish.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tzdb;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const AstroApp());

const signs = ['Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];
const zoneMap = ['East (E6)','North-West (W7)','North-North-West','North-North-East','East-North-East','North','West-South-West','South-West (S7)','North-East','South-South-East (S6)','West (W6)','South'];
const hiSigns = ['मेष','वृषभ','मिथुन','कर्क','सिंह','कन्या','तुला','वृश्चिक','धनु','मकर','कुंभ','मीन'];
const hiZones = ['पूर्व (E6)','उत्तर-पश्चिम (W7)','उत्तर-उत्तर-पश्चिम','उत्तर-उत्तर-पूर्व','पूर्व-उत्तर-पूर्व','उत्तर','पश्चिम-दक्षिण-पश्चिम','दक्षिण-पश्चिम (S7)','उत्तर-पूर्व','दक्षिण-दक्षिण-पूर्व (S6)','पश्चिम (W6)','दक्षिण'];

String cuspZoneText(double longitude,bool hindi){
 final sign=(longitude/30).floor()%12; final within=longitude%30; final active=<int>[sign];
 if(within<=4.0) active.add((sign+11)%12);
 if(within>=26.0) active.add((sign+1)%12);
 return active.toSet().map((i)=>hindi?hiZones[i]:zoneMap[i]).join(' + ');
}
const planetNames = {Planet.sun:'Sun',Planet.moon:'Moon',Planet.mars:'Mars',Planet.mercury:'Mercury',Planet.jupiter:'Jupiter',Planet.venus:'Venus',Planet.saturn:'Saturn',Planet.meanNode:'Rahu'};
const hiPlanetNames = {'Sun':'सूर्य','Moon':'चंद्रमा','Mars':'मंगल','Mercury':'बुध','Jupiter':'बृहस्पति','Venus':'शुक्र','Saturn':'शनि','Rahu':'राहु','Ketu':'केतु'};

class AstroApp extends StatelessWidget {
 const AstroApp({super.key});
 @override Widget build(BuildContext context) => MaterialApp(title:'Jyotish Astro-Vastu',debugShowCheckedModeBanner:false,theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff8f4b2b),brightness:Brightness.light),useMaterial3:true),home:const EntryPage());
}

class EntryPage extends StatefulWidget { const EntryPage({super.key}); @override State<EntryPage> createState()=>_EntryPageState(); }
class _EntryPageState extends State<EntryPage> {
 final formKey=GlobalKey<FormState>(); final name=TextEditingController(); final place=TextEditingController(text:'New Delhi'); final lat=TextEditingController(text:'28.6139'); final lon=TextEditingController(text:'77.2090'); final tz=TextEditingController(text:'Asia/Kolkata'); final date=TextEditingController(text:'1990-01-01'); final time=TextEditingController(text:'12:00');
 bool hindi=false, busy=false; VedicChart? chart; DashaResult? dasha; String? err;
 final jyotish=Jyotish(); bool _engineReady=false;
 @override void initState(){super.initState();}
 @override void dispose(){for(final c in [name,place,lat,lon,tz,date,time]){c.dispose();}super.dispose();}
 String? requiredText(String? s)=>s==null||s.trim().isEmpty?'Required':null;
 Future<void> calculate() async {
  if(!formKey.currentState!.validate())return;
  setState(()=>busy=true);
  try {
   if(!_engineReady){final dir=Directory('${(await getApplicationSupportDirectory()).path}/ephe');await dir.create(recursive:true);for(final file in ['seas_18.se1','semo_18.se1','sepl_18.se1']){final bytes=await rootBundle.load('assets/ephe/$file');await File('${dir.path}/$file').writeAsBytes(bytes.buffer.asUint8List(),flush:true);}await jyotish.initialize(ephemerisPath:dir.path);_engineReady=true;}
   final parts=date.text.trim().split('-'); final hm=time.text.trim().split(':');
   tzd.initializeTimeZones();
   final zone=tzdb.getLocation(tz.text.trim());
   final local=tzdb.TZDateTime(zone,int.parse(parts[0]),int.parse(parts[1]),int.parse(parts[2]),int.parse(hm[0]),int.parse(hm[1]));
   final utc=local.toUtc();
   final location=GeographicLocation(latitude:double.parse(lat.text),longitude:double.parse(lon.text),timezone:tz.text.trim());
   // Supply an absolute UTC instant; this keeps the library's ephemeris and cusps on the same birth moment.
   final res=await jyotish.calculateVedicChart(dateTime:utc,location:location,houseSystem:'P',flags:CalculationFlags.kp());
   final ds=await jyotish.getVimshottariDasha(natalChart:res);
   if(mounted)setState(() { chart=res; dasha=ds; err=null; });
  } catch(e){if(mounted)setState(()=>err='Calculation failed: $e');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context){
  final title=hindi?'ज्योतिष · एस्ट्रो-वास्तु रिपोर्ट':'Jyotish · Astro-Vastu Report';
  return Scaffold(backgroundColor:const Color(0xfff6f1e9),appBar:AppBar(title:Text(title),backgroundColor:const Color(0xfff6f1e9),actions:[TextButton(onPressed:()=>setState(()=>hindi=!hindi),child:Text(hindi?'English':'हिन्दी'))]),body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760),child:ListView(padding:const EdgeInsets.all(20),children:[
  Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:const Color(0xff43291f),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(hindi?'जन्म विवरण से अपनी कुंडली और वास्तु रिपोर्ट बनाएं':'Generate your birth chart and Vastu report',style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(hindi?'KP sidereal · 12 भाव · ग्रह स्थिति · Vimshottari दशा · PDF':'KP sidereal · 12 houses · planetary placements · Vimshottari dasha · PDF',style:const TextStyle(color:Color(0xffecd6c2)))])),
  const SizedBox(height:18),Card(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),child:Padding(padding:const EdgeInsets.all(18),child:Form(key:formKey,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(hindi?'जन्म विवरण':'Birth details',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:12),_field(name,hindi?'नाम (वैकल्पिक)':'Name (optional)',optional:true),Row(children:[Expanded(child:_field(date,hindi?'जन्म तिथि (YYYY-MM-DD)':'Birth date (YYYY-MM-DD)')),const SizedBox(width:12),Expanded(child:_field(time,hindi?'स्थानीय समय (HH:MM)':'Local time (HH:MM)'))]),_field(place,hindi?'जन्म स्थान':'Birth place'),Row(children:[Expanded(child:_field(lat,'Latitude')),const SizedBox(width:12),Expanded(child:_field(lon,'Longitude'))]),_field(tz,hindi?'IANA समय क्षेत्र (जैसे Asia/Kolkata)':'IANA time zone (e.g. Asia/Kolkata)'),const SizedBox(height:10),SizedBox(width:double.infinity,height:52,child:FilledButton.icon(onPressed:busy?null:calculate,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.auto_awesome),label:Text(busy?(hindi?'गणना हो रही है…':'Calculating…'):(hindi?'कुंडली बनाएं':'Calculate chart')))),if(err!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(err!,style:const TextStyle(color:Colors.red))) ])))),
  if(chart!=null)...[const SizedBox(height:16),_resultCard(),const SizedBox(height:12),FilledButton.tonalIcon(onPressed:()=>_printPdf(),icon:const Icon(Icons.picture_as_pdf),label:Text(hindi?'PDF रिपोर्ट बनाएं / साझा करें':'Create / share PDF report')),const Padding(padding:EdgeInsets.only(top:12),child:Text('Astrology is a traditional interpretive system, not a scientifically established prediction method. Vastu suggestions are informational; they are not medical, financial or safety advice.',style:TextStyle(fontSize:11,color:Colors.black54)))],
  const SizedBox(height:24),const Text('Calculation note: KP sidereal (VP291) + Placidus cusps are selected to reflect the sample Kundli format in the uploaded PDFs. The source PDFs also contain an inconsistent “Lahiri + KP Placidus” label; this app keeps the KP system internally consistent.',style:TextStyle(fontSize:11,color:Colors.black54))
 ]))));
 }
 Widget _field(TextEditingController c,String label,{bool optional=false})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextFormField(controller:c,validator:optional?null:requiredText,decoration:InputDecoration(labelText:label,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)),filled:true,fillColor:const Color(0xfffbfaf7)),keyboardType:(c==lat||c==lon)?const TextInputType.numberWithOptions(decimal:true):TextInputType.text));
 Widget _resultCard(){final c=chart!;final asc=(c.houses.ascendant/30).floor()%12;final nm=hindi?hiSigns[asc]:signs[asc];final zn=cuspZoneText(c.houses.ascendant,hindi);final md=dasha?.currentMahadasha;return Card(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(hindi?'कुंडली सारांश':'Chart summary',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text('${hindi?'लग्न':'Ascendant'}: $nm  ·  ${hindi?'दिशा':'Zone'}: $zn'),Text('${hindi?'भाव प्रणाली':'House system'}: KP Placidus · ${hindi?'अयनांश':'Ayanamsa'}: KP VP291'),Text('${hindi?'जन्म नक्षत्र':'Birth Nakshatra'}: ${dasha?.birthNakshatra??'—'} · Pada ${dasha?.birthPada??'—'}'),if(md!=null)Text('${hindi?'वर्तमान महादशा':'Current Mahadasha'}: ${md.lordName??md.lord?.name??'—'} · ${DateFormat('dd MMM yyyy').format(md.startDate)} – ${DateFormat('dd MMM yyyy').format(md.endDate)}'),const Divider(),..._planetRows(c,hindi)])));}
 List<Widget> _planetRows(VedicChart c,bool hi){
  final rows=<Widget>[];
  for(final e in c.planets.entries){final p=e.value;final n=planetNames[e.key]??e.key.name;final si=(p.longitude/30).floor()%12;rows.add(Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Text('${hi?hiPlanetNames[n]??n:n}: ${hi?hiSigns[si]:signs[si]} ${(p.longitude%30).toStringAsFixed(2)}° · H${p.house}${p.isRetrograde?' ℞':''}')));}
  final si=(c.ketu.longitude/30).floor()%12;rows.add(Text('${hi?'केतु':'Ketu'}: ${hi?hiSigns[si]:signs[si]} ${(c.ketu.longitude%30).toStringAsFixed(2)}°'));
  return rows;
 }

 Future<void> _printPdf()async{final data=await _makePdf();await Printing.layoutPdf(onLayout:(_)=>data,name:'Astro-Vastu-${name.text.isEmpty?'Report':name.text}.pdf');}
 Future<Uint8List> _makePdf()async{
  final c=chart!;final doc=pw.Document();final hi=hindi;final asc=(c.houses.ascendant/30).floor()%12; final devanagari=pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf'));
  final pdfTheme=pw.ThemeData.withFont(base:hi?devanagari:pw.Font.helvetica(),bold:hi?devanagari:pw.Font.helveticaBold());
  final planets=<Map<String,String>>[];
  for(final e in c.planets.entries){final p=e.value;final n=planetNames[e.key]??e.key.name;final si=(p.longitude/30).floor()%12;planets.add({'planet':hi?hiPlanetNames[n]??n:n,'sign':hi?hiSigns[si]:signs[si],'degree':(p.longitude%30).toStringAsFixed(2),'house':'${p.house}','nak':p.nakshatra,'zone':cuspZoneText(p.longitude,hi)});}
  final k=c.ketu; final ks=(k.longitude/30).floor()%12;planets.add({'planet':hi?'केतु':'Ketu','sign':hi?hiSigns[ks]:signs[ks],'degree':(k.longitude%30).toStringAsFixed(2),'house':'—','nak':k.nakshatra,'zone':cuspZoneText(k.longitude,hi)});
  final md=dasha?.currentMahadasha;final born=DateTime.parse('${date.text}T${time.text}:00');
  doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(38),theme:pdfTheme,build:(ctx)=>[
   pw.Container(padding:const pw.EdgeInsets.all(18),decoration:const pw.BoxDecoration(color:PdfColor.fromInt(0xff43291f)),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text(hi?'ज्योतिष · एस्ट्रो-वास्तु रिपोर्ट':'JYOTISH · ASTRO-VASTU REPORT',style:pw.TextStyle(color:PdfColors.white,fontSize:20,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:5),pw.Text('${name.text.trim().isEmpty?(hi?'जन्म कुंडली':'Birth chart'):name.text} · ${DateFormat('dd MMM yyyy').format(born)} ${time.text}',style:const pw.TextStyle(color:PdfColors.white,fontSize:10))])),
   pw.SizedBox(height:16),pw.Text('${hi?'जन्म स्थान':'Birth place'}: ${place.text}  (${lat.text}, ${lon.text}; ${tz.text})',style:const pw.TextStyle(fontSize:10)),pw.SizedBox(height:8),pw.Text('${hi?'लग्न':'Ascendant'}: ${hi?hiSigns[asc]:signs[asc]} · ${hi?'वास्तु क्षेत्र':'Astro-Vastu direction'}: ${cuspZoneText(c.houses.ascendant,hi)}',style:pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold)),pw.Text(hi?'गणना: KP sidereal VP291 अयनांश · Placidus भाव':'Calculation: KP sidereal VP291 ayanamsa · Placidus houses',style:const pw.TextStyle(fontSize:9)),
   pw.SizedBox(height:14),pw.Text(hi?'ग्रह स्थिति':'Planetary placements',style:pw.TextStyle(fontSize:15,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:6),pw.TableHelper.fromTextArray(headers:[hi?'ग्रह':'Planet',hi?'राशि':'Sign',hi?'अंश':'Degree',hi?'भाव':'House',hi?'नक्षत्र':'Nakshatra',hi?'दिशा':'Direction'],data:planets.map((p)=>['${p['planet']}','${p['sign']}','${p['degree']}°','${p['house']}','${p['nak']}','${p['zone']}']).toList(),border:pw.TableBorder.all(color:PdfColors.grey400,width:.5),headerStyle:pw.TextStyle(fontSize:8,fontWeight:pw.FontWeight.bold),cellStyle:const pw.TextStyle(fontSize:8),headerDecoration:const pw.BoxDecoration(color:PdfColor.fromInt(0xffeee5d8)),cellPadding:const pw.EdgeInsets.all(4)),
   pw.SizedBox(height:14),pw.Text(hi?'भाव-कस्प और वास्तु क्षेत्र':'House cusp → Astro-Vastu direction',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:5),pw.TableHelper.fromTextArray(headers:[hi?'भाव':'House',hi?'राशि':'Sign',hi?'कस्प अंश':'Cusp longitude',hi?'वास्तु दिशा':'Zone'],data:List.generate(12,(i){final deg=c.houses.cusps[i];final si=(deg/30).floor()%12;return ['${i+1}',hi?hiSigns[si]:signs[si],'${(deg%30).toStringAsFixed(2)}°',cuspZoneText(deg,hi)];}),border:pw.TableBorder.all(color:PdfColors.grey400,width:.5),headerStyle:pw.TextStyle(fontSize:8,fontWeight:pw.FontWeight.bold),cellStyle:const pw.TextStyle(fontSize:8),headerDecoration:const pw.BoxDecoration(color:PdfColor.fromInt(0xffeee5d8)),cellPadding:const pw.EdgeInsets.all(4)),
   pw.SizedBox(height:14),pw.Text('${hi?'जन्म नक्षत्र':'Birth Nakshatra'}: ${dasha?.birthNakshatra??'—'} · Pada ${dasha?.birthPada??'—'}',style:const pw.TextStyle(fontSize:9)),pw.SizedBox(height:5),pw.Text(hi?'वर्तमान विम्शोत्तरी महादशा':'Current Vimshottari Mahadasha',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),if(md!=null)pw.Text('${md.lordName??md.lord?.name??''}: ${DateFormat('dd MMM yyyy').format(md.startDate)} – ${DateFormat('dd MMM yyyy').format(md.endDate)}',style:const pw.TextStyle(fontSize:10)),
   pw.SizedBox(height:14),pw.Text(hi?'विम्शोत्तरी महादशा क्रम':'Vimshottari Mahadasha timeline',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:5),pw.TableHelper.fromTextArray(headers:[hi?'ग्रह':'Lord',hi?'शुरू':'From',hi?'समाप्त':'To',hi?'वर्ष':'Years'],data:(dasha?.allMahadashas??[]).map((d)=>[d.lordName??d.lordDisplayName,DateFormat('dd MMM yyyy').format(d.startDate),DateFormat('dd MMM yyyy').format(d.endDate),(d.duration.inDays/365.2425).toStringAsFixed(1)]).toList(),border:pw.TableBorder.all(color:PdfColors.grey400,width:.5),headerStyle:pw.TextStyle(fontSize:8,fontWeight:pw.FontWeight.bold),cellStyle:const pw.TextStyle(fontSize:8),headerDecoration:const pw.BoxDecoration(color:PdfColor.fromInt(0xffeee5d8)),cellPadding:const pw.EdgeInsets.all(4)),
   pw.SizedBox(height:14),pw.Text(hi?'एस्ट्रो-वास्तु फ्रेमवर्क':'Astro-Vastu framework',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.Text(hi?'अपलोड किए गए Astro-Vastu मार्गदर्शकों के अनुसार हर भाव की कस्प राशि वास्तु दिशा-क्षेत्र से जोड़ा गया है। सामान्य दिशाएँ: मेष–पूर्व, वृषभ–उत्तर-पश्चिम, मिथुन–उत्तर-उत्तर-पश्चिम, कर्क–उत्तर-उत्तर-पूर्व, सिंह–पूर्व-उत्तर-पूर्व, कन्या–उत्तर, तुला–पश्चिम-दक्षिण-पश्चिम, वृश्चिक–दक्षिण-पश्चिम, धनु–उत्तर-पूर्व, मकर–दक्षिण-दक्षिण-पूर्व, कुंभ–पश्चिम, मीन–दक्षिण।':'This report applies the uploaded Astro-Vastu guide’s sign-to-direction mapping to each house cusp: Aries–East, Taurus–NW, Gemini–NNW, Cancer–NNE, Leo–ENE, Virgo–North, Libra–WSW, Scorpio–SW, Sagittarius–NE, Capricorn–SSE/South, Aquarius–West, Pisces–South.',style:const pw.TextStyle(fontSize:9)),pw.SizedBox(height:6),pw.Text(hi?'व्यावहारिक नियम: (1) भाव से जुड़ी गतिविधि उस भाव के कस्प राशि वाले दिशा-क्षेत्र में रखें। (2) भाव में स्थित ग्रहों के guide-mapped objects उसी क्षेत्र में देखें। (3) ग्रह-हिट/मिश्रित वस्तु नियम केवल तभी लागू करें जब chart-specific hit angle और source rule उपलब्ध हों; यह रिपोर्ट स्वतः असत्यापित वस्तु-उपाय नहीं बनाती।':'Use the cusp-sign direction for the house’s associated activity. The guides also place objects associated with planets occupying that house in that direction. Their hit/mixed-object remedies require a verified chart-specific aspect/hit rule; this report does not invent object prescriptions where the source data is insufficient.',style:const pw.TextStyle(fontSize:9)),
   pw.SizedBox(height:15),pw.Divider(),pw.Text(hi?'महत्वपूर्ण: ज्योतिष पारंपरिक व्याख्यात्मक प्रणाली है, वैज्ञानिक रूप से प्रमाणित भविष्यवाणी नहीं। वास्तु सुझाव सामान्य जानकारी हैं—चिकित्सा, वित्त, कानूनी या सुरक्षा सलाह नहीं।':'Important: Astrology is a traditional interpretive practice, not a scientifically established predictive method. Vastu notes are informational and are not medical, financial, legal, or safety advice.',style:const pw.TextStyle(fontSize:8,color:PdfColors.grey700)),pw.SizedBox(height:4),pw.Text('Source basis: supplied Astro-Vastu PDFs (Assignments 1–7) and sample Kundli PDFs. Calculation choice: KP VP291 + Placidus, selected for internal consistency.',style:const pw.TextStyle(fontSize:7,color:PdfColors.grey600))
  ]));return doc.save();
 }
}
