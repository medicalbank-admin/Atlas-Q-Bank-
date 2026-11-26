const PROJECT_ID="the-atlas-academy-3fae0";
const ISSUER="https://securetoken.google.com/"+PROJECT_ID;
const KEYS_URL="https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const TOKEN_URL="https://oauth2.googleapis.com/token";
const DOCS="https://firestore.googleapis.com/v1/projects/"+PROJECT_ID+"/databases/(default)/documents";
const FCM="https://fcm.googleapis.com/v1/projects/"+PROJECT_ID+"/messages:send";
const CORS={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"POST, OPTIONS","Access-Control-Allow-Headers":"Authorization, Content-Type"};
let keyCache=null,accessCache=null;
function json(v,s){return new Response(JSON.stringify(v),{status:s||200,headers:Object.assign({},CORS,{"Content-Type":"application/json"})});}
function b64(v){const a=typeof v==="string"?new TextEncoder().encode(v):v;let s="";for(const x of a)s+=String.fromCharCode(x);return btoa(s).replace(/=/g,"").replace(/\+/g,"-").replace(/\//g,"_");}
function un64(v){const s=v.replace(/-/g,"+").replace(/_/g,"/");return Uint8Array.from(atob(s+"=".repeat((4-s.length%4)%4)),c=>c.charCodeAt(0));}
function part(v){return JSON.parse(new TextDecoder().decode(un64(v)));}
async function verify(token,adminOnly){adminOnly=adminOnly!==false;const p=token.split(".");if(p.length!==3)throw Error("Sign in again.");const h=part(p[0]),c=part(p[1]);if(h.alg!=="RS256"||!h.kid)throw Error("Invalid administrator token.");if(!keyCache||keyCache.until<Date.now()){const r=await fetch(KEYS_URL);if(!r.ok)throw Error("Unable to verify account.");const keySet=await r.json();const keys=Array.isArray(keySet)?keySet:keySet.keys;if(!Array.isArray(keys)||keys.length===0)throw Error("Firebase returned an invalid signing-key set.");keyCache={keys,until:Date.now()+3600000};}const jwk=keyCache.keys.find(x=>x.kid===h.kid);if(!jwk)throw Error("Token signing key expired.");const k=await crypto.subtle.importKey("jwk",jwk,{name:"RSASSA-PKCS1-v1_5",hash:"SHA-256"},false,["verify"]);const valid=await crypto.subtle.verify("RSASSA-PKCS1-v1_5",k,un64(p[2]),new TextEncoder().encode(p[0]+"."+p[1]));const now=Math.floor(Date.now()/1000);if(!valid||c.iss!==ISSUER||c.aud!==PROJECT_ID||!c.sub||c.exp<=now||c.iat>now+60||(adminOnly&&c.admin!==true))throw Error(adminOnly?"Administrator permission is required.":"A valid sign-in is required.");return c;}
function pem(p){return Uint8Array.from(atob(p.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g,"")),c=>c.charCodeAt(0));}
async function access(env){if(accessCache&&accessCache.until>Date.now()+60000)return accessCache.token;const a=JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);const now=Math.floor(Date.now()/1000);const head=b64(JSON.stringify({alg:"RS256",typ:"JWT"}));const claim=b64(JSON.stringify({iss:a.client_email,scope:"https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging",aud:TOKEN_URL,iat:now,exp:now+3600}));const unsigned=head+"."+claim;const key=await crypto.subtle.importKey("pkcs8",pem(a.private_key),{name:"RSASSA-PKCS1-v1_5",hash:"SHA-256"},false,["sign"]);const sig=await crypto.subtle.sign("RSASSA-PKCS1-v1_5",key,new TextEncoder().encode(unsigned));const form=new URLSearchParams({grant_type:"urn:ietf:params:oauth:grant-type:jwt-bearer",assertion:unsigned+"."+b64(new Uint8Array(sig))});const r=await fetch(TOKEN_URL,{method:"POST",headers:{"Content-Type":"application/x-www-form-urlencoded"},body:form});const d=await r.json();if(!r.ok||!d.access_token)throw Error("Unable to obtain Firebase service credentials.");accessCache={token:d.access_token,until:Date.now()+(Number(d.expires_in)||3600)*1000};return d.access_token;}
async function firestore(env,path,options){const token=await access(env);const r=await fetch(DOCS+path,Object.assign({headers:{Authorization:"Bearer "+token,"Content-Type":"application/json"}},options||{}));const d=await r.json().catch(()=>({}));if(!r.ok)throw Error(d.error&&d.error.message?d.error.message:"Firestore request failed.");return d;}
function val(f,k){const x=f&&f[k];if(!x)return null;if(x.stringValue!==undefined)return x.stringValue;if(x.booleanValue!==undefined)return x.booleanValue;if(x.integerValue!==undefined)return Number(x.integerValue);if(x.doubleValue!==undefined)return Number(x.doubleValue);if(x.timestampValue!==undefined)return x.timestampValue;if(x.arrayValue)return (x.arrayValue.values||[]).map(v=>v.stringValue||"");if(x.mapValue)return decode(x.mapValue.fields||{});return null;}
function decode(fields){const o={};for(const k in fields)o[k]=val(fields,k);return o;}
function enc(v){if(v===null)return {nullValue:null};if(typeof v==="string")return {stringValue:v};if(typeof v==="boolean")return {booleanValue:v};if(typeof v==="number")return Number.isInteger(v)?{integerValue:String(v)}:{doubleValue:v};return {stringValue:String(v)};}
async function patchDoc(env,path,fields){const names=Object.keys(fields);const q=names.map(k=>"updateMask.fieldPaths="+encodeURIComponent(k)).join("&");const body={fields:{}};for(const k of names)body.fields[k]=enc(fields[k]);return firestore(env,path+"?"+q,{method:"PATCH",body:JSON.stringify(body)});}
async function listCollection(env,name,limit){const token=await access(env);const r=await fetch(DOCS+":runQuery",{method:"POST",headers:{Authorization:"Bearer "+token,"Content-Type":"application/json"},body:JSON.stringify({structuredQuery:{from:[{collectionId:name}],limit:limit||5000}})});const d=await r.json();if(!r.ok)throw Error(d.error&&d.error.message||"Unable to read "+name);return (Array.isArray(d)?d:[]).filter(x=>x.document).map(x=>({name:x.document.name,id:x.document.name.split("/").pop(),data:decode(x.document.fields||{})}));}
async function getUser(env,uid){try{return decode((await firestore(env,"/users/"+encodeURIComponent(uid))).fields||{});}catch(_){return {};}}
function matches(u,b){const a=b.audience||"all";if(a==="selected")return (b.userIds||[]).includes(u.uid);if(a==="plan"){const p=String(u.membershipPlan||u.planName||u.subscriptionPlanName||"");return p.toLowerCase()===String(b.membershipPlan||"").toLowerCase();}if(a==="pathway"){const p=String(u.medicalPathway||u.pathway||u.selectedPathway||"");return p.toLowerCase()===String(b.medicalPathway||"").toLowerCase();}if(a==="status"){const s=String(u.subscriptionStatus||u.membershipStatus||"inactive").toLowerCase();return s===String(b.subscriptionStatus||"").toLowerCase();}return true;}
async function createInboxNotice(env,id,uid,b){
const safeId=String(id||"push_notice").replace(/[^A-Za-z0-9_-]/g,"_").slice(0,90)+"_"+String(uid).slice(0,40);
const token=await access(env);
const fields={
 userId:{stringValue:String(uid)},
 audience:{stringValue:"selected"},
 isActive:{booleanValue:true},
 title:{stringValue:String(b.title||"The Atlas Academy")},
 body:{stringValue:String(b.body||"You have a new academy notification.")},
 destination:{stringValue:String(b.destination||"")},
 createdAt:{timestampValue:new Date().toISOString()}
};
const r=await fetch(DOCS+"/notifications?documentId="+encodeURIComponent(safeId),{
 method:"POST",
 headers:{Authorization:"Bearer "+token,"Content-Type":"application/json"},
 body:JSON.stringify({fields})
});
if(r.status===409)return false;
if(!r.ok){const d=await r.json().catch(()=>({}));throw Error(d.error&&d.error.message||"Unable to save student inbox notification.");}
return true;
}
async function sendCampaign(env,b){const all=await listCollection(env,"user_device_tokens",5000);const byUid=new Map();for(const row of all){const d=row.data;if(d.active!==true||!d.token||!d.userId)continue;if(!byUid.has(d.userId))byUid.set(d.userId,[]);byUid.get(d.userId).push(d.token);}
const users=[];for(const [uid,tokens] of byUid){const u=await getUser(env,uid);u.uid=uid;if(matches(u,b))for(const token of tokens)users.push({uid:uid,token:token});}
const results={sent:0,failed:0,devices:users.length};const bearer=await access(env);
for(let i=0;i<users.length;i+=20){const group=users.slice(i,i+20);const replies=await Promise.all(group.map(x=>fetch(FCM,{method:"POST",headers:{Authorization:"Bearer "+bearer,"Content-Type":"application/json"},body:JSON.stringify({message:{token:x.token,notification:{title:b.title,body:b.body,image:b.imageUrl||undefined},data:{notificationId:b.notificationId||"",destination:b.destination||"",screen:"notifications"},android:{priority:"high",notification:{sound:"default",image:b.imageUrl||undefined}},apns:{payload:{aps:{sound:"default"}},fcm_options:b.imageUrl?{image:b.imageUrl}:undefined}}})})));for(let j=0;j<replies.length;j++){if(replies[j].ok)results.sent++;else{results.failed++;if(replies[j].status===404||replies[j].status===400){try{await patchDoc(env,"/user_device_tokens/"+encodeURIComponent(users[i+j].token),{active:false});}catch(_){}}}}}
const inboxRecipients=[...new Set(users.map(x=>x.uid))];
const inboxId=String(b.notificationId||("push_"+Date.now()));
for(let i=0;i<inboxRecipients.length;i+=25){
 const batch=inboxRecipients.slice(i,i+25);
 await Promise.all(batch.map(uid=>createInboxNotice(env,inboxId,uid,b).catch(()=>false)));
}
return results;}
async function sendAdminCampaign(env,b){
 const rows=await listCollection(env,"user_device_tokens",5000);
 const admins=new Map();
 for(const row of rows){const d=row.data;if(d.active!==true||d.isAdmin!==true||!d.token||!d.userId)continue;if(!admins.has(d.userId))admins.set(d.userId,new Set());admins.get(d.userId).add(d.token);}
 const targets=[];for(const [uid,tokens] of admins)for(const token of tokens)targets.push({uid,token});
 const result={sent:0,failed:0,devices:targets.length};if(!targets.length)return result;
 const bearer=await access(env);
 for(let i=0;i<targets.length;i+=20){const group=targets.slice(i,i+20);const replies=await Promise.all(group.map(x=>fetch(FCM,{method:"POST",headers:{Authorization:"Bearer "+bearer,"Content-Type":"application/json"},body:JSON.stringify({message:{token:x.token,notification:{title:b.title,body:b.body},data:{notificationId:b.notificationId||"",destination:b.destination||"inbox",screen:"notifications"},android:{priority:"high",notification:{sound:"default"}},apns:{payload:{aps:{sound:"default"}}}}})})));for(let j=0;j<replies.length;j++){if(replies[j].ok)result.sent++;else{result.failed++;if(replies[j].status===404||replies[j].status===400){try{await patchDoc(env,"/user_device_tokens/"+encodeURIComponent(targets[i+j].token),{active:false});}catch(_){}}}}}
 const recipients=[...admins.keys()];for(const uid of recipients){await createInboxNotice(env,b.notificationId,uid,b).catch(()=>false);}
 return result;
}
async function createLog(env,id,fields){const token=await access(env);const body={fields:{}};for(const k in fields)body.fields[k]=enc(fields[k]);const r=await fetch(DOCS+"/push_notifications?documentId="+encodeURIComponent(id),{method:"POST",headers:{Authorization:"Bearer "+token,"Content-Type":"application/json"},body:JSON.stringify(body)});if(r.status===409)return false;if(!r.ok){const d=await r.json().catch(()=>({}));throw Error(d.error&&d.error.message||"Unable to save notification log.");}return true;}
async function processExpiryReminders(env){const rows=await listCollection(env,"users",5000);const now=Date.now();for(const row of rows){const u=row.data;const uid=row.id;const expiry=u.subscriptionExpiryAt;if(!expiry||u.subscriptionStatus!=="active")continue;const date=Date.parse(expiry);if(!Number.isFinite(date))continue;const days=Math.ceil((date-now)/86400000);if(![7,3,1,0].includes(days))continue;const logId="membership_expiry_"+uid+"_"+days;let exists=true;try{await firestore(env,"/push_notifications/"+encodeURIComponent(logId));}catch(_){exists=false;}if(exists)continue;const body=days===0?"Your membership expires today. Renew now to avoid interruption.":"Your membership expires in "+days+" days. Renew early to keep your learning access active.";const payload={notificationId:logId,title:days===0?"Membership expires today":"Membership renewal reminder",body:body,destination:"membership",audience:"selected",userIds:[uid]};try{const result=await sendCampaign(env,payload);if(result.devices>0){await createLog(env,logId,{title:payload.title,body:body,audience:"selected",status:"sent",sentCount:result.sent,failedCount:result.failed,deviceCount:result.devices,createdAt:new Date().toISOString(),automaticType:"membership_expiry",studentUid:uid,daysRemaining:days});}}catch(_){} }}
async function processExamAlerts(env){let exams=[];try{exams=await listCollection(env,"exams",1000);}catch(_){return;}const now=Date.now();for(const row of exams){const e=row.data;if(e.isPublished!==true)continue;const published=e.publishedAt||e.updatedAt||e.createdAt;const publishedMs=Date.parse(published||"");if(Number.isFinite(publishedMs)&&now-publishedMs<10*60*1000){const id="exam_published_"+row.id;let exists=true;try{await firestore(env,"/push_notifications/"+encodeURIComponent(id));}catch(_){exists=false;}if(!exists){const title=String(e.title||e.name||"New mock examination");const body="A new mock examination is now available. Open Examinations to view the details.";const result=await sendCampaign(env,{notificationId:id,title:title,body:body,destination:"examinations",audience:"all"});if(result.devices>0)await createLog(env,id,{title:title,body:body,status:"sent",audience:"all",sentCount:result.sent,failedCount:result.failed,deviceCount:result.devices,createdAt:new Date().toISOString(),automaticType:"exam_published"});}}
const deadline=e.deadlineAt||e.endAt||e.closesAt||e.scheduledEndAt;if(deadline){const ms=Date.parse(deadline);const hours=(ms-now)/3600000;if(hours>0&&hours<=24){const id="exam_deadline_"+row.id;let exists=true;try{await firestore(env,"/push_notifications/"+encodeURIComponent(id));}catch(_){exists=false;}if(!exists){const title="Mock exam deadline approaching";const body=String(e.title||e.name||"Your mock exam")+" closes within 24 hours. Complete it before the deadline.";const result=await sendCampaign(env,{notificationId:id,title:title,body:body,destination:"examinations",audience:"all"});if(result.devices>0)await createLog(env,id,{title:title,body:body,status:"sent",audience:"all",sentCount:result.sent,failedCount:result.failed,deviceCount:result.devices,createdAt:new Date().toISOString(),automaticType:"exam_deadline"});}}}}}
async function processScheduled(env){const rows=await listCollection(env,"push_notifications",500);const now=Date.now();for(const row of rows){const b=row.data;if(b.status!=="scheduled"||!b.scheduledAt||Date.parse(b.scheduledAt)>now)continue;try{await patchDoc(env,"/push_notifications/"+row.id,{status:"sending"});b.notificationId=row.id;const r=await sendCampaign(env,b);await patchDoc(env,"/push_notifications/"+row.id,{status:"sent",sentCount:r.sent,failedCount:r.failed,deviceCount:r.devices,sentAt:new Date().toISOString()});}catch(e){try{await patchDoc(env,"/push_notifications/"+row.id,{status:"failed",error:String(e.message||e)});}catch(_){}}}await processExpiryReminders(env);await processExamAlerts(env);}

async function deviceEndpoint(request, env, claims, action) {
  const body = await request.json();
  const uid = claims.sub;
  if (claims.admin === true) return json({ success: true, exempt: true, admin: true });
  const deviceId = String(body.deviceId || "");
  if (!/^[A-Za-z0-9_-]{24,100}$/.test(deviceId)) return json({ success:false, message:"Invalid device identity." },400);
  const path = "/device_sessions/" + encodeURIComponent(uid);
  if (action === "validate") {
    let current = null;
    try { current = decode((await firestore(env, path)).fields || {}); } catch (_) {}
    if (!current || current.deviceId !== deviceId) {
      return json({ success:false, code:"device_replaced", message:"This account is active on another device. Please sign in again on your registered device." },409);
    }
    await patchDoc(env, path, { lastSeenAt:new Date().toISOString() });
    return json({ success:true, admin:false });
  }
  const ip = request.headers.get("CF-Connecting-IP") || "";
  const cf = request.cf || {};
  const country = String(cf.country || "");
  const asn = Number(cf.asn || 0);
  const organization = String(cf.asOrganization || "");
  const proxyPattern = /(vpn|proxy|hosting|cloud|data ?center|datacenter|digitalocean|amazon|aws|google cloud|microsoft azure|ovh|hetzner|vultr|linode|oracle cloud)/i;
  const proxyFlag = proxyPattern.test(organization);
  let previous = null;
  try { previous = decode((await firestore(env, path)).fields || {}); } catch (_) {}
  const replaced = !!(previous && previous.deviceId && previous.deviceId !== deviceId);
  const suspicious = proxyFlag || !!(previous && previous.country && country && previous.country !== country);
  const now = new Date().toISOString();
  await patchDoc(env, path, {
    userId:uid, deviceId, platform:String(body.platform || "mobile"),
    deviceLabel:String(body.deviceLabel || "Registered device").slice(0,100),
    lastIp:ip, country, asn, networkOrganization:organization,
    proxySuspected:proxyFlag, securityReviewRequired:suspicious || replaced,
    lastSeenAt:now, boundAt:replaced ? now : (previous && previous.boundAt || now),
    previousDeviceId:replaced ? previous.deviceId : (previous && previous.previousDeviceId || "")
  });
  if (suspicious || replaced) {
    const id = "device_" + uid + "_" + Date.now();
    const fields = {
      userId:uid, deviceId, previousDeviceId:replaced ? previous.deviceId : "",
      event:proxyFlag ? "possible_vpn_or_proxy" : (replaced ? "device_changed" : "unusual_country"),
      reviewStatus:"pending", ipAddress:ip, country, asn,
      networkOrganization:organization, createdAt:now,
      details:proxyFlag ? "Network organization resembles a hosting, VPN or proxy provider; this is a heuristic signal." :
        (replaced ? "The account was registered from a different app installation." : "The sign-in country differs from the previous device.")
    };
    const encoded = {};
    for (const key in fields) encoded[key] = enc(fields[key]);
    await firestore(env, "/device_security_events?documentId=" + encodeURIComponent(id), {
      method:"POST", body:JSON.stringify({fields:encoded})
    });
  }
  return json({ success:true, admin:false, replaced, reviewRequired:suspicious || replaced,
    message:replaced ? "This device is now the only registered device for this account." : "Device registered." });
}

export default {
 async fetch(request,env){if(request.method==="OPTIONS")return new Response(null,{headers:CORS});const url=new URL(request.url);if(url.pathname==="/health")return json({success:true,service:"atlas-academy-push-api"});if(request.method!=="POST"||!["/send","/event","/device/register","/device/validate"].includes(url.pathname))return json({success:false,message:"Not found."},404);
 try{const auth=request.headers.get("Authorization")||"";if(!auth.startsWith("Bearer "))return json({success:false,message:"Sign-in required."},401);const claims=await verify(auth.slice(7),url.pathname==="/send");if(url.pathname==="/device/register"||url.pathname==="/device/validate")return await deviceEndpoint(request,env,claims,url.pathname.endsWith("validate")?"validate":"register");const b=await request.json();
 if(url.pathname==="/event"){
 if(b.type==="chapter_published"&&typeof b.resourceId==="string"){
  if(claims.admin!==true)return json({success:false,message:"Administrator permission is required."},403);
  const resourceId=b.resourceId.trim();
  const resource=decode((await firestore(env,"/learning_resources/"+encodeURIComponent(resourceId))).fields||{});
  if(resource.isPublished!==true)return json({success:false,message:"This chapter is not published."},403);
  const version=Number(resource.versionNumber||0);
  if(!Number.isInteger(version)||version<1)return json({success:false,message:"Published chapter version is invalid."},400);
  const notificationId="chapter_update_"+resourceId+"_v"+version;
  try{await firestore(env,"/push_notifications/"+encodeURIComponent(notificationId));return json({success:true,duplicate:true,sent:0,failed:0,devices:0});}catch(_){}
  const title="Chapter updated: "+String(resource.title||"Medical chapter");
  const body="A new version (v"+version+") is available in Learning Resources. Download the chapter again to refresh your offline copy.";
  const payload={notificationId,title,body,destination:"study_library",audience:"all"};
  const users=await listCollection(env,"users",5000);
  const students=users.filter(row=>row.data.isAdmin!==true&&String(row.data.role||"").toLowerCase()!=="admin"&&String(row.data.accountType||"").toLowerCase()!=="admin");
  for(let i=0;i<students.length;i+=25){
   await Promise.all(students.slice(i,i+25).map(row=>createInboxNotice(env,notificationId,row.id,payload).catch(()=>false)));
  }
  const result=await sendCampaign(env,payload);
  await createLog(env,notificationId,{title,body,audience:"all",status:"sent",sentCount:result.sent,failedCount:result.failed,deviceCount:result.devices,createdAt:new Date().toISOString(),automaticType:"chapter_published",resourceId,versionNumber:version});
  return json({success:true,...result,inAppRecipients:students.length});
 }
 if(b.type==="forum_reply"&&typeof b.postId==="string"){const post=decode((await firestore(env,"/forum_posts/"+encodeURIComponent(b.postId))).fields||{});const recipient=String(post.userId||"");if(!recipient||recipient===claims.sub)return json({success:true,sent:0,failed:0,devices:0});const payload={notificationId:"forum_reply_"+b.postId+"_"+Date.now(),title:"New discussion reply",body:"Someone has replied to your discussion: "+String(post.title||"Student discussion"),destination:"forum_thread:"+b.postId,audience:"selected",userIds:[recipient]};const eventResult=await sendCampaign(env,payload);if(eventResult.devices>0)await createLog(env,payload.notificationId,{title:payload.title,body:payload.body,audience:"selected",status:"sent",sentCount:eventResult.sent,failedCount:eventResult.failed,deviceCount:eventResult.devices,createdAt:new Date().toISOString(),automaticType:"forum_reply"});return json({success:true,...eventResult});}
 if(b.type==="subscription_request"&&typeof b.requestId==="string"){
  if(claims.admin===true)return json({success:false,message:"A student account must submit this event."},403);
  const req=decode((await firestore(env,"/subscription_requests/"+encodeURIComponent(b.requestId))).fields||{});
  if(req.studentUid!==claims.sub||req.status!=="pending")return json({success:false,message:"Subscription request not found or no longer pending."},403);
  const payload={notificationId:"subscription_request_"+b.requestId,title:"New subscription request",body:String(req.studentName||"A student")+" submitted a payment request for "+String(req.planName||"a membership plan")+".",destination:"subscriptions",audience:"admin"};
  const result=await sendAdminCampaign(env,payload);
  await createLog(env,payload.notificationId,{title:payload.title,body:payload.body,audience:"admin",status:"sent",sentCount:result.sent,failedCount:result.failed,deviceCount:result.devices,createdAt:new Date().toISOString(),automaticType:"subscription_request"});
  return json({success:true,...result});
 }
 if(b.type==="subscription_decision"&&typeof b.requestId==="string"){
  if(claims.admin!==true)return json({success:false,message:"Administrator permission is required."},403);
  const req=decode((await firestore(env,"/subscription_requests/"+encodeURIComponent(b.requestId))).fields||{});
  if(!req.studentUid||!["approved","rejected"].includes(req.status))return json({success:false,message:"The reviewed subscription request could not be found."},404);
  const approved=req.status==="approved";
  const payload={notificationId:"subscription_"+req.status+"_"+b.requestId,title:approved?"Membership approved":"Subscription request update",body:approved?"Your "+String(req.planName||"")+" membership is now active. Enjoy your academy access.":"Your subscription request was not approved. "+String(req.adminNote||"Please contact the academy for details."),destination:"membership",audience:"selected",userIds:[req.studentUid]};
  const result=await sendCampaign(env,payload);
  await createLog(env,payload.notificationId,{title:payload.title,body:payload.body,audience:"selected",status:"sent",sentCount:result.sent,failedCount:result.failed,deviceCount:result.devices,createdAt:new Date().toISOString(),automaticType:"subscription_"+req.status});
  return json({success:true,...result});
 }
 if(b.type==="inbox_message"&&typeof b.studentUid==="string"&&typeof b.messageId==="string"){
  const studentUid=b.studentUid;
  const message=decode((await firestore(env,"/inbox_conversations/"+encodeURIComponent(studentUid)+"/messages/"+encodeURIComponent(b.messageId))).fields||{});
  if(message.senderUid!==claims.sub)return json({success:false,message:"Message sender could not be verified."},403);
  const conversation=decode((await firestore(env,"/inbox_conversations/"+encodeURIComponent(studentUid))).fields||{});
  if(conversation.studentUid!==studentUid)return json({success:false,message:"Conversation not found."},404);
  const fromAdmin=claims.admin===true;
  if(!fromAdmin&&claims.sub!==studentUid)return json({success:false,message:"You are not a participant in this conversation."},403);
  const payload={notificationId:"inbox_message_"+b.messageId,title:fromAdmin?"New message from The Atlas Academy":"New student message",body:String(message.body||"You received a photo attachment."),destination:"inbox",audience:"selected",userIds:[studentUid]};
  const result=fromAdmin?await sendCampaign(env,payload):await sendAdminCampaign(env,payload);
  await createLog(env,payload.notificationId,{title:payload.title,body:payload.body,audience:fromAdmin?"selected":"admin",status:"sent",sentCount:result.sent,failedCount:result.failed,deviceCount:result.devices,createdAt:new Date().toISOString(),automaticType:"inbox_message"});
  return json({success:true,...result});
 }
 return json({success:false,message:"Unsupported notification event."},400);
}
 b.title=String(b.title||"").trim();b.body=String(b.body||"").trim();if(!b.title||!b.body||b.title.length>120||b.body.length>2000)return json({success:false,message:"A title and message are required."},400);if(b.audience==="selected"&&!Array.isArray(b.userIds))return json({success:false,message:"Selected student IDs are required."},400);const sendResult=await sendCampaign(env,b);if(b.notificationId){try{await patchDoc(env,'/push_notifications/'+encodeURIComponent(b.notificationId),{status:'sent',sentCount:sendResult.sent,failedCount:sendResult.failed,deviceCount:sendResult.devices,sentAt:new Date().toISOString()});}catch(_){try{await createLog(env,b.notificationId,{title:b.title,body:b.body,audience:b.audience||'all',status:'sent',sentCount:sendResult.sent,failedCount:sendResult.failed,deviceCount:sendResult.devices,createdAt:new Date().toISOString(),automaticType:'event'});}catch(__){}}}return json({success:true,...sendResult});}catch(e){return json({success:false,message:e.message||"Push delivery failed."},400);}},
 async scheduled(event,env,ctx){ctx.waitUntil(processScheduled(env));}
};