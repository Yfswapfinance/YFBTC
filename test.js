total = 21000
startBlock = 2500;
function getReward(_from, _to){
  total = 0
  difference = _to - _from;
  if ( difference <=0 ){
      difference = 1;
  }
  if (_from >= startBlock && _to <= startBlock + 1036800){
      
      if (_to <= startBlock.add(172800)){
        total = 4643333333333333000000 /  172800;
      }
      else{
        total = 8641973370000000;
      }
  }else if(_from >= startBlock && _to <= startBlock + (2073600)){
    total = 4320987650000000;
  }
  else if(_from >= startBlock && _to <= startBlock + (3110400)){
      total = 2160493820000000;
  }
  else if(_from >= startBlock && _to <= startBlock + (4147200)){
      total = 1080246910000000;
  }
  else if(_from >= startBlock && _to <= startBlock + (5184000)){
    total  = 540123450000000;
  }
  else if(_from >= startBlock && _to <= startBlock + (6220800)){
    total = 270061720000000;
  }
  else if(_from >= startBlock && _to <= startBlock + (7257600)){
    total = 135030860000000;
  }
  else if(_from >= startBlock && _to <= startBlock + (8294400)){
    total = 67515430000000;
  }else{
  return 0;
  }
}
console.log(getReward(266, 2073600))