import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/atlas_academy_app.dart';
class AtlasLogo extends StatelessWidget{
 final double size;
 const AtlasLogo({super.key,this.size=56});
 @override Widget build(BuildContext context)=>SvgPicture.asset('assets/logo/atlas_academy_logo.svg',width:size,height:size,fit:BoxFit.contain,placeholderBuilder:(_)=>Icon(Icons.school_rounded,size:size*.7,color:AtlasColors.champagne));
}