function force( fcn )

  MPP_FORCE_exists = false;
  try
    MPP_FORCE_val = evalin('caller','MPP_FORCE');
    MPP_FORCE_exists = true;
  end
    
  MPP_BROKEN_exists = false;
  try
    MPP_BROKEN_val = evalin('caller','MPP_BROKEN');
    MPP_BROKEN_exists = true;
  end
  
  assignin('caller','MPP_FORCE',true);
  try
    evalin('caller',fcn);
  end
  
  if MPP_FORCE_exists
    assignin('caller','MPP_FORCE',MPP_FORCE_val);
  else
    evalin('caller','clear(''MPP_FORCE'');');
  end

  if MPP_BROKEN_exists
    assignin('caller','MPP_BROKEN',MPP_BROKEN_val);
  else
    evalin('caller','clear(''MPP_BROKEN'');');
  end
  
  
end