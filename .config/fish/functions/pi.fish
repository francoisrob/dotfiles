function pi --wraps pi --description 'pi with its temp files in hub/scratch/tmp'
    TMPDIR=$HOME/hub/scratch/tmp command pi $argv
end
