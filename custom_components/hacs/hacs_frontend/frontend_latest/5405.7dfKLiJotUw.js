export const id=5405;export const ids=[5405];export const modules={1040:(t,e,i)=>{i.d(e,{A:()=>n});const a=t=>t<10?`0${t}`:t;function n(t){const e=Math.floor(t/3600),i=Math.floor(t%3600/60),n=Math.floor(t%3600%60);return e>0?`${e}:${a(i)}:${a(n)}`:i>0?`${i}:${a(n)}`:n>0?""+n:null}},54708:(t,e,i)=>{i.d(e,{PF:()=>r,CR:()=>n,ls:()=>s});i(16891);var a=i(1040);const n=(t,e)=>t.callWS({type:"timer/create",...e}),s=t=>{if(!t.attributes.remaining)return;let e=function(t){const e=t.split(":").map(Number);return 3600*e[0]+60*e[1]+e[2]}(t.attributes.remaining);if("active"===t.state){const i=(new Date).getTime(),a=new Date(t.last_changed).getTime();e=Math.max(e-(i-a)/1e3,0)}return e},r=(t,e,i)=>{if(!e)return null;if("idle"===e.state||0===i)return t.formatEntityState(e);let n=(0,a.A)(i||0)||"0";return"paused"===e.state&&(n=`${n} (${t.formatEntityState(e)})`),n}},5405:(t,e,i)=>{i.r(e);var a=i(36312),n=i(68689),s=i(66360),r=i(29818),l=i(54708);(0,a.A)([(0,r.EM)("ha-timer-remaining-time")],(function(t,e){class i extends e{constructor(...e){super(...e),t(this)}}return{F:i,d:[{kind:"field",decorators:[(0,r.MZ)({attribute:!1})],key:"hass",value:void 0},{kind:"field",decorators:[(0,r.MZ)({attribute:!1})],key:"stateObj",value:void 0},{kind:"field",decorators:[(0,r.wk)()],key:"timeRemaining",value:void 0},{kind:"field",key:"_updateRemaining",value:void 0},{kind:"method",key:"createRenderRoot",value:function(){return this}},{kind:"method",key:"update",value:function(t){(0,n.A)(i,"update",this,3)([t]),this.innerHTML=(0,l.PF)(this.hass,this.stateObj,this.timeRemaining)??"-"}},{kind:"method",key:"connectedCallback",value:function(){(0,n.A)(i,"connectedCallback",this,3)([]),this.stateObj&&this._startInterval(this.stateObj)}},{kind:"method",key:"disconnectedCallback",value:function(){(0,n.A)(i,"disconnectedCallback",this,3)([]),this._clearInterval()}},{kind:"method",key:"willUpdate",value:function(t){(0,n.A)(i,"willUpdate",this,3)([t]),t.has("stateObj")&&this._startInterval(this.stateObj)}},{kind:"method",key:"_clearInterval",value:function(){this._updateRemaining&&(clearInterval(this._updateRemaining),this._updateRemaining=null)}},{kind:"method",key:"_startInterval",value:function(t){this._clearInterval(),this._calculateRemaining(t),"active"===t.state&&(this._updateRemaining=setInterval((()=>this._calculateRemaining(this.stateObj)),1e3))}},{kind:"method",key:"_calculateRemaining",value:function(t){this.timeRemaining=(0,l.ls)(t)}}]}}),s.mN)}};
//# sourceMappingURL=5405.7dfKLiJotUw.js.map