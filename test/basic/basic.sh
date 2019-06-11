for i in *.asm ; do
    f=`basename ${i} .asm`
    asm71 ${i},${f}.lex,${f}.lst,R2
    echo "Comparing lst file"
    diff ${f}.lst reference/${f}.lst
    echo "Comparing lex file"
    diff ${f}.lex reference/${f}.lex
    rm -f ${f}.lex
    rm -f ${f}.lst
done
