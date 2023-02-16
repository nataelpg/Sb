.section .data
    INI_HEAP: .quad 0
    FIM_HEAP: .quad 0 

    END_A: .quad 0
    END_B: .quad 0
    END_C: .quad 0
    END_D: .quad 0

    MINIMO: .quad 0
    END_MINIMO: .quad 0
    TOPO_UTIL: .quad 0

    ULT_END: .quad 0
    NOVO_FIM: .quad 0

    BYTE_LIVRE: .string "-"
    BYTE_OCUPADO: .string "+"
    CHAR_LINHA: .string "\n"
    STR_GERENCIAL: .string "################"

.section .text
.globl _start
iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax        # inicializa a heap alterando seu valor
    movq $0, %rdi
    syscall

    movq %rax, INI_HEAP   # move o valor atual de brk para INI_HEAP
    movq %rax, FIM_HEAP   # move o valor atual de brk para FIM_HEAP
    movq %rax, TOPO_UTIL  # move o valor atual de brk para TOPO_UTIL

    popq %rbp
    ret

finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax
    movq INI_HEAP, %rdi
    syscall

    popq %rbp
    ret
    
liberaMem:
    push %rbp
    movq %rsp, %rbp
    movq 16(%rbp), %r8      # guarda o endereco do bloco passado como parametro p/liberacao

    movq $0, -16(%r8)         # armazena valor indicando que o bloco esta livre
    movq -16(%r8), %rbx

    popq %rbp
    ret
       
first_fit:
    pushq %rbp
    movq %rsp, %rbp
    movq 16(%rbp), %rbx     # parâmetro num_bytes
    movq INI_HEAP, %r8     # passa inicio da heap para variavel local

    jmp procura_bloco_livre
    cmpq $0, %rax           # verifica valor de retorno da funcao
    jne fim                  # se foi encontrado bloco livre, encerra
    aloca_novo:             # se nao, aumenta heap
    movq 16(%rbp), %rbx     # parâmetro num_bytes
    movq $12, %rax          # caso a heap esteja vazia, aloca num_bytes
    addq FIM_HEAP, %rbx
    addq $16, %rbx
    movq %rbx, %rdi        # rbx = num_bytes + 16
    syscall    

    movq FIM_HEAP, %r8
    movq $1, (%r8)          # guarda que bloco esta ocupado
    movq 16(%rbp), %r9      # pega tamanho do bloco passado como parametro
    movq %r9, 8(%r8)       # guarda tamanho do bloco
    addq $16, %r8
    movq %r8, %rax
    movq %rbx, FIM_HEAP     # atualiza fim da heap

    fim:
    popq %rbp
    ret

procura_bloco_livre:
    movq INI_HEAP, %rbx
    movq 16(%rbp), %r8      # tamanho passado como parametro na pilha para bloco novo
    
    busca:
        cmpq %rbx, FIM_HEAP
        jle nao_tem_bloco_livre 

        cmpq $0, (%rbx)  # compara se o bloco esta livre comparando com 0, 0 = bloco livre!
        je bloco_livre   # se for 0, bloco disponivel para alocacao
    
        continua_busca:
        movq 8(%rbx), %r8  #
        addq %r8, %rbx
        addq $16, %rbx
        jmp busca

    bloco_livre:
        movq 8(%rbx), %r9       # r9 = tamanho do bloco encontrado
        cmpq %r9, %r8           # compara tamanho do bloco com tamanho desejado para alocacao 
        jl continua_busca       # se o bloco for menor, continua a busca
        movq $1, (%rbx)         # coloca 1 no bloco indicando que esta ocupado
        addq $16, %rbx          # acrescente 16 no endereco p/onde comeca o bloco
        movq %rbx, %rax         # retorna o endereco inicial do bloco
        jmp fim

    nao_tem_bloco_livre:
        movq $0, %rax
        jmp aloca_novo


best_fit:
    push %rbp
    movq %rsp, %rbp
    subq $8, %rsp         # aloca variavel local
    movq $0, -8(%rbp)     # guarda que inicialmente nao foi encontrado bloco livre, 0 = nao encontrado 1 = encontrado !!
    movq INI_HEAP, %rbx          
    movq 16(%rbp), %r8      # tamanho passado como parametro na pilha para bloco novo
    
    cmpq %rbx, FIM_HEAP
    je aloca_novo_bf
    movq %rbx, END_MINIMO   # endereco do primeiro bloco p/comparacao
    movq 8(%rbx), %r10
    movq %r10, MINIMO    # tamanho do primeiro bloco p/comparacao

    busca_bf:
        cmpq %rbx, FIM_HEAP
        jle aloca_mem_bf

        cmpq $0, (%rbx)  # compara se o bloco esta livre comparando com 0, 0 = bloco livre!
        je bloco_livre_bf   # se for 0, bloco disponivel para alocacao


        continua_busca_bf:
            movq 8(%rbx), %r8  #
            addq %r8, %rbx
            addq $16, %rbx
            jmp busca_bf

    bloco_livre_bf:
        movq $1, -8(%rbp)       # guarda que foi encontrado bloco livre
        movq 8(%rbx), %r9       # r9 = tamanho do bloco encontrado
        cmpq %r9, %r8           # compara tamanho do bloco com tamanho desejado para alocacao 
        jl continua_busca_bf       # se o bloco for menor, continua a busca
        cmpq MINIMO, %r9            # compara tamanho do bloco com o tamanho minimo, se for maior que o minimo, continua a busca
        jg continua_busca_bf
        movq %r9, MINIMO
        movq %rbx, END_MINIMO   # endereco do comeco do bloco minimo 
        jmp continua_busca_bf

    aloca_mem_bf:
        cmpq $1, -8(%rbp)       # verifica se variavel local tem 1, ou seja, foi enconrtado blocolivre !!
        jne aloca_novo_bf       # se nao, aloca novo bloco na heap
        movq END_MINIMO, %rbx   # endereco do bloco de tamanho minimo
        movq $1, (%rbx)         # coloca 1 no bloco indicando que esta ocupado
        addq $16, %rbx          # acrescente 16 no endereco p/onde comeca o bloco
        movq %rbx, %rax         # retorna o endereco inicial do bloco
        jmp fim_bf

    aloca_novo_bf:             # se nao, aumenta heap
        movq 16(%rbp), %rbx     # parâmetro num_bytes
        movq $12, %rax          # caso a heap esteja vazia, aloca num_bytes
        addq FIM_HEAP, %rbx
        addq $16, %rbx
        movq %rbx, %rdi        # rbx = num_bytes + 16
        syscall    

        movq FIM_HEAP, %r8
        movq $1, (%r8)          # guarda que bloco esta ocupado
        movq 16(%rbp), %r9      # pega tamanho do bloco passado como parametro
        movq %r9, 8(%r8)       # guarda tamanho do bloco
        addq $16, %r8
        movq %r8, %rax
        movq %rbx, FIM_HEAP     # atualiza fim da heap

    fim_bf:
        addq $8, %rsp
        popq %rbp
        ret

aloca_4096:
    pushq %rbp
    movq %rsp, %rbp
    movq 16(%rbp), %rbx     # parâmetro num_bytes

    inicio:
        movq TOPO_UTIL, %r9     # pega o topo da pilha
        movq FIM_HEAP, %r10     # pega o fim da heap
        subq %r9, %r10          # subtrai o topo da pilha do fim da heap
        movq 16(%rbp), %r13     # coloca o valor a ser alocado em r13
        addq $16, %r13          # adiciona o valor real a ser alocado, 16 bytes para informação e tamanho do bloco
        cmpq %r10, %r13         # compara o tamanho do bloco com o tamanho da pilha disponivel
        jg aloca_novo4096       # se o tamanho desejado for maior que o tamanho disponivel na pilha, aloca novo bloco na heap

        movq TOPO_UTIL, %r9     # pega o topo da pilha
        movq $1, (%r9)          # guarda que bloco esta ocupado
        movq 16(%rbp), %r10     # pega tamanho do bloco passado como parametro
        movq %r10, 8(%r9)       # guarda tamanho do bloco
        addq $16, %r9           # acrescenta espaço para o byte ocupado e tamanho do bloco
        movq %r9, %rax          # retorna o endereco inicial do bloco
        addq %rbx, %r9          # acrescenta o tamanho do bloco
        movq %r9, TOPO_UTIL     # atualiza topo da pilha
        jmp fim4096   


    aloca_novo4096:             # se nao, aumenta heap
        movq $4096, %r11
        movq $12, %rax          # atualiza o valor de brk
        addq FIM_HEAP, %r11
        movq %r11, %rdi         
        movq %r11, FIM_HEAP     # atualiza fim da heap
        syscall

        jmp inicio    

    fim4096:
        popq %rbp
        ret

next_fit:
    pushq %rbp
    movq %rsp, %rbp
    movq 16(%rbp), %r10          # tamanho do bloco a ser alocado passado como parametro
    movq INI_HEAP, %r8
    movq FIM_HEAP, %r9
    

    cmpq %r8, %r9               # verifica se a heap tem bloco ocupado
    je  aloca_novo_nf           # entao a variavel recebe o inicio da heap
    movq ULT_END, %rbx           # caso nao seja, o endereco onde parou a ultima alocacao eh passado pra rbx
    jmp busca_nf                  
    
    continua_busca_nf:
        movq 8(%rbx), %r11  # guarda tamanho do bloco
        addq %r11, %rbx 
        addq $16, %rbx

    busca_nf:
        cmpq %r9, %rbx          # compara fim da heap com ponteiro que percorre a lista
        jge reinicia_busca
        movq NOVO_FIM, %r13
        cmpq %r13, %rbx         # compara o novo fim da heap com ponteiro que percorre a lista
        je aloca_novo_nf
        cmpq $1, (%rbx)         # verifica se bloco esta livre
        je continua_busca_nf
        movq 8(%rbx), %r11      # r11 = tamanho do bloco encontrado
        cmpq %r11, %r10         # compara tamanho do bloco encontrado com tamanho do bloco p/alocacao
        jg continua_busca_nf    # se tamanho do bloco encontrado for menor, continua busca
        movq $1, (%rbx)         # coloca 1 no comeco do bloco, indicando que esta ocupado
        movq %rbx, ULT_END
        jmp fim_nf

    reinicia_busca:             
        movq %r8, %rbx   # retorna a busca para comeco da heap
        movq ULT_END, %r13
        movq %r13, NOVO_FIM
        jmp busca_nf

    aloca_novo_nf:
        movq 16(%rbp), %rbx     # parâmetro num_bytes
        movq $12, %rax          # caso a heap esteja vazia, aloca num_bytes
        addq FIM_HEAP, %rbx
        addq $16, %rbx
        movq %rbx, %rdi         # rbx = num_bytes + 16
        syscall    

        movq FIM_HEAP, %r8
        movq $1, (%r8)          # guarda que bloco esta ocupado
        movq 16(%rbp), %r9      # pega tamanho do bloco passado como parametro
        movq %r9, 8(%r8)        # guarda tamanho do bloco
        addq $16, %r8
        movq %r8, %rax
        movq %rbx, FIM_HEAP     # atualiza fim da heap
        subq $16, %r8
        movq %r8, ULT_END       # atualiza ultimo endereco

    fim_nf:
        popq %rbp
        ret

imprimeMapa:
    pushq %rbp
    movq %rsp, %rbp

    subq $8, %rsp               # aloca espaço para variável local
    movq INI_HEAP, %r12         # armazena valor do inicio da heap
    movq FIM_HEAP, %r10         # armazena valor do fim da heap
    movq %r10, -8(%rbp)         

    while_bloco:
        cmpq -8(%rbp), %r12             # verifica se o ponteiro chegou ao fim da heap
        jge fim_imprime
        movq $STR_GERENCIAL, %rsi    # armazena mensagem de gerenciamento
        movq $16, %rdx              # armazena valores para syscall write
        movq $1, %rax               
        movq $1, %rdi               
        syscall                     # chama a syscall write
        
        movq (%r12), %r13           # pega o bit de ocupacao do bloco
        movq 8(%r12), %r14          # pega o tamanho do bloco
        movq $0, %r15               # contador i
        while_imprime:
        cmpq %r14, %r15             # imprime o tamanho do bloco em caracteres ate o tamanho do bloco
        jge fim_while_imprime
            movq $1, %rdi           # argumentos para o write
            movq $1, %rdx
            movq $1, %rax
            cmpq $0, %r13           # se 0 imprime BYTE_LIVRE, se 1 imprime BYTE_OCUPADO
            jne imprime_else        
                movq $BYTE_LIVRE, %rsi       # imprime BYTE_LIVRE "-"
                jmp fim_if          # fim imprime_if             
            imprime_else:
                movq $BYTE_OCUPADO, %rsi     # imprime BYTE_OCUPADO "+"
            fim_if:
                syscall
                addq $1, %r15                   # r15 (i)++
                jmp while_imprime               # volta para o while_imprime
            
        fim_while_imprime:
            addq $16, %r12                      
            addq %r14, %r12                     # atualiza o ponteiro para o proximo bloco
            jmp while_bloco
        
    fim_imprime:
        movq $CHAR_LINHA, %rsi        # imprime charLinha "_"
        movq $1, %rdx                # argumentos para o write 
        movq $1, %rax
        movq $1, %rdi
        syscall

        addq $8, %rsp
        popq %rbp
        ret

_start:

    call iniciaAlocador

    movq $50, %rbx           # empilha num_bytes
    pushq %rbx  
    call next_fit
    addq $8, %rsp
    movq %rax, END_A       # guarda o endereco do primeiro bloco alocado

    movq $200, %rbx           # empilha num_bytes
    pushq %rbx  
    call next_fit
    addq $8, %rsp
    movq %rax, END_B       # guarda o endereco do primeiro bloco alocado

    movq $150, %rbx           # empilha num_bytes
    pushq %rbx  
    call next_fit
    addq $8, %rsp
    movq %rax, END_C       # guarda o endereco do primeiro bloco alocado

    movq END_A, %rbx           # empilha num_bytes
    pushq %rbx  
    call liberaMem
    addq $8, %rsp
    movq %rax, END_A       # guarda o endereco do primeiro bloco alocado

    movq END_C, %rbx           # empilha num_bytes
    pushq %rbx  
    call liberaMem
    addq $8, %rsp
    movq %rax, END_C       # guarda o endereco do primeiro bloco alocado


    movq $50, %rbx           # empilha num_bytes
    pushq %rbx  
    call next_fit
    addq $8, %rsp
    movq %rax, END_D       # guarda o endereco do primeiro bloco alocado

    movq $150, %rbx           # empilha num_bytes
    pushq %rbx  
    call next_fit
    addq $8, %rsp
    movq %rax, END_C       # guarda o endereco do primeiro bloco alocado

    call imprimeMapa

    call finalizaAlocador
    movq $60, %rax
    movq $0, %rdi
    syscall

