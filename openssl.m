openssl ; openssl wrapper class


dgst(string,type)       ; Public ; Generate a message digest
        ; Usage:
        ;  s digest=$$dgst^openssl(string,type)
        ; Inputs:
        ;  string = plain text input
        ;  type = message digest type (sha, sha1, sha512, etc)
        ; Outputs:
        ;  $$dgst = digest of plain text input
        ;
        n i,f,g,x
        ;
        i $g(type)="" s type="sha1"
        ;
        s io=$i
        s f="/tmp/openssl.digest.input."_$j_".tmp"
        s g="/tmp/openssl.digest.output."_$j_".tmp"
        ;
        o f:NEW
        u f w string
        c f
        ;
        zsystem "/usr/bin/openssl dgst -"_type_" <"_f_" >"_g
        o f
        c f:DELETE
        ;
        o g:READ
        u g r x
        c g:DELETE
        ;
        u io
        ;
        q x



enc(string,cipher,password,mode)        ; Public
        ; Usage:
        ;  s output=$$enc^openssl(string,cipher,password,mode)
        ; Inputs:
        ;  string = plain text input
        ;  cipher = encryption cipher (bf, des, aes256, etc)
        ;  password = password for encryption
        ;  mode = e - encrypt, d - decrypt
        ; Outputs:
        ;  $$enc = encrypted or decrypted string
        ; Notes:
        ;  All encrypted strings are base64 encoded
        ;
        n i,f,g,x
        ;
        i string="" q "" ; Don't try to decrypt nothing
        ;
        i $g(cipher)="" s type="bf"
        ;
        s io=$i
        s f="/tmp/openssl.cipher.input."_$j_".tmp"
        s g="/tmp/openssl.cipher.output."_$j_".tmp"
        ;
        o f:NEW
        u f w string
        c f
        ;
        zsystem "/usr/bin/openssl enc -"_cipher_" -"_mode_" -a -A -salt -pass pass:"_password_" -in "_f_" -out "_g
        o f
        c f:DELETE
        ;
        o g:READ
        u g r x
        c g:DELETE
        ;
        u io
        ;
        q x
