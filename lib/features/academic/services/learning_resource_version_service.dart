import 'package:cloud_firestore/cloud_firestore.dart';

class LearningResourceVersionService {
  static CollectionReference<Map<String, dynamic>> _versions(String id) =>
      FirebaseFirestore.instance.collection('learning_resources').doc(id).collection('versions');

  static Future<int> save({required String resourceId, required Map<String,dynamic> content,
    required bool publish, required bool isNew}) async {
    final db=FirebaseFirestore.instance;
    final ref=db.collection('learning_resources').doc(resourceId);
    final snap=isNew?null:await ref.get();
    final current=snap?.data()??<String,dynamic>{};
    var version=(current['versionNumber'] as num?)?.toInt()??0;
    final batch=db.batch();
    if(publish){
      if(snap!=null && snap.exists && current['isPublished']==true && version==0){
        version=1;
        batch.set(_versions(resourceId).doc('v1'),{...current,'versionNumber':1,
          'savedAt':FieldValue.serverTimestamp(),'changeNote':'Archived previous published chapter'});
      }
      version++;
      batch.set(_versions(resourceId).doc('v$version'),{...content,'versionNumber':version,
        'savedAt':FieldValue.serverTimestamp(),'changeNote':isNew?'Initial publication':'Published revision'});
    }
    batch.set(ref,{...content,'versionNumber':version,'isPublished':publish,
      if(isNew)'createdAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
    await batch.commit();
    return version;
  }

  static Future<void> restore({required String resourceId,required int selectedVersion}) async {
    final db=FirebaseFirestore.instance;
    final ref=db.collection('learning_resources').doc(resourceId);
    final chosen=await _versions(resourceId).doc('v$selectedVersion').get();
    final currentSnap=await ref.get();
    if(!chosen.exists||!currentSnap.exists) throw StateError('Selected revision is unavailable.');
    final current=currentSnap.data()??<String,dynamic>{};
    final selected=chosen.data()??<String,dynamic>{};
    var next=(current['versionNumber'] as num?)?.toInt()??0;
    final batch=db.batch();
    if(current['isPublished']==true && next>0){
      next++;
      batch.set(_versions(resourceId).doc('v$next'),{...current,'versionNumber':next,
        'savedAt':FieldValue.serverTimestamp(),'changeNote':'Archived before restoring v$selectedVersion'});
    }
    next++;
    final restored=Map<String,dynamic>.from(selected)
      ..remove('savedAt')..remove('changeNote')..remove('versionNumber')
      ..remove('createdAt')..remove('updatedAt');
    batch.update(ref,{...restored,'versionNumber':next,'isPublished':true,
      'updatedAt':FieldValue.serverTimestamp()});
    batch.set(_versions(resourceId).doc('v$next'),{...restored,'versionNumber':next,
      'savedAt':FieldValue.serverTimestamp(),'changeNote':'Restored from version $selectedVersion'});
    await batch.commit();
  }
}