#if defined(__has_feature)
#if __has_feature(memory_sanitizer) && !defined(OPENSSL_NO_ASM)
#define OPENSSL_NO_ASM
#endif
#endif

#if !defined(OPENSSL_NO_ASM)
#if defined(__arm__)
#include <GFp/arm_arch.h>

#if __ARM_MAX_ARCH__>=7
.text
.arch	armv7-a	@ don't confuse not-so-latest binutils with argv8 :-)
.fpu	neon
.code	32
#undef	__thumb2__
.align	5
.Lrcon:
.long	0x01,0x01,0x01,0x01
.long	0x0c0f0e0d,0x0c0f0e0d,0x0c0f0e0d,0x0c0f0e0d	@ rotate-n-splat
.long	0x1b,0x1b,0x1b,0x1b

.globl	GFp_aes_hw_set_encrypt_key
.hidden	GFp_aes_hw_set_encrypt_key
.type	GFp_aes_hw_set_encrypt_key,%function
.align	5
GFp_aes_hw_set_encrypt_key:
.Lenc_key:
	mov	r3,#-1
	cmp	r0,#0
	beq	.Lenc_key_abort
	cmp	r2,#0
	beq	.Lenc_key_abort
	mov	r3,#-2
	cmp	r1,#128
	blt	.Lenc_key_abort
	cmp	r1,#256
	bgt	.Lenc_key_abort
	tst	r1,#0x3f
	bne	.Lenc_key_abort

	adr	r3,.Lrcon
	cmp	r1,#192

	veor	q0,q0,q0
	vld1.8	{q3},[r0]!
	mov	r1,#8		@ reuse r1
	vld1.32	{q1,q2},[r3]!

	blt	.Loop128
	beq	.L192
	b	.L256

.align	4
.Loop128:
	vtbl.8	d20,{q3},d4
	vtbl.8	d21,{q3},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q3},[r2]!
.byte	0x00,0x43,0xf0,0xf3	@ aese q10,q0
	subs	r1,r1,#1

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q10,q10,q1
	veor	q3,q3,q9
	vshl.u8	q1,q1,#1
	veor	q3,q3,q10
	bne	.Loop128

	vld1.32	{q1},[r3]

	vtbl.8	d20,{q3},d4
	vtbl.8	d21,{q3},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q3},[r2]!
.byte	0x00,0x43,0xf0,0xf3	@ aese q10,q0

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q10,q10,q1
	veor	q3,q3,q9
	vshl.u8	q1,q1,#1
	veor	q3,q3,q10

	vtbl.8	d20,{q3},d4
	vtbl.8	d21,{q3},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q3},[r2]!
.byte	0x00,0x43,0xf0,0xf3	@ aese q10,q0

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q10,q10,q1
	veor	q3,q3,q9
	veor	q3,q3,q10
	vst1.32	{q3},[r2]
	add	r2,r2,#0x50

	mov	r12,#10
	b	.Ldone

.align	4
.L192:
	vld1.8	{d16},[r0]!
	vmov.i8	q10,#8			@ borrow q10
	vst1.32	{q3},[r2]!
	vsub.i8	q2,q2,q10	@ adjust the mask

.Loop192:
	vtbl.8	d20,{q8},d4
	vtbl.8	d21,{q8},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{d16},[r2]!
.byte	0x00,0x43,0xf0,0xf3	@ aese q10,q0
	subs	r1,r1,#1

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9

	vdup.32	q9,d7[1]
	veor	q9,q9,q8
	veor	q10,q10,q1
	vext.8	q8,q0,q8,#12
	vshl.u8	q1,q1,#1
	veor	q8,q8,q9
	veor	q3,q3,q10
	veor	q8,q8,q10
	vst1.32	{q3},[r2]!
	bne	.Loop192

	mov	r12,#12
	add	r2,r2,#0x20
	b	.Ldone

.align	4
.L256:
	vld1.8	{q8},[r0]
	mov	r1,#7
	mov	r12,#14
	vst1.32	{q3},[r2]!

.Loop256:
	vtbl.8	d20,{q8},d4
	vtbl.8	d21,{q8},d5
	vext.8	q9,q0,q3,#12
	vst1.32	{q8},[r2]!
.byte	0x00,0x43,0xf0,0xf3	@ aese q10,q0
	subs	r1,r1,#1

	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q3,q3,q9
	vext.8	q9,q0,q9,#12
	veor	q10,q10,q1
	veor	q3,q3,q9
	vshl.u8	q1,q1,#1
	veor	q3,q3,q10
	vst1.32	{q3},[r2]!
	beq	.Ldone

	vdup.32	q10,d7[1]
	vext.8	q9,q0,q8,#12
.byte	0x00,0x43,0xf0,0xf3	@ aese q10,q0

	veor	q8,q8,q9
	vext.8	q9,q0,q9,#12
	veor	q8,q8,q9
	vext.8	q9,q0,q9,#12
	veor	q8,q8,q9

	veor	q8,q8,q10
	b	.Loop256

.Ldone:
	str	r12,[r2]
	mov	r3,#0

.Lenc_key_abort:
	mov	r0,r3			@ return value

	bx	lr
.size	GFp_aes_hw_set_encrypt_key,.-GFp_aes_hw_set_encrypt_key
.globl	GFp_aes_hw_encrypt
.hidden	GFp_aes_hw_encrypt
.type	GFp_aes_hw_encrypt,%function
.align	5
GFp_aes_hw_encrypt:
	ldr	r3,[r2,#240]
	vld1.32	{q0},[r2]!
	vld1.8	{q2},[r0]
	sub	r3,r3,#2
	vld1.32	{q1},[r2]!

.Loop_enc:
.byte	0x00,0x43,0xb0,0xf3	@ aese q2,q0
.byte	0x84,0x43,0xb0,0xf3	@ aesmc q2,q2
	vld1.32	{q0},[r2]!
	subs	r3,r3,#2
.byte	0x02,0x43,0xb0,0xf3	@ aese q2,q1
.byte	0x84,0x43,0xb0,0xf3	@ aesmc q2,q2
	vld1.32	{q1},[r2]!
	bgt	.Loop_enc

.byte	0x00,0x43,0xb0,0xf3	@ aese q2,q0
.byte	0x84,0x43,0xb0,0xf3	@ aesmc q2,q2
	vld1.32	{q0},[r2]
.byte	0x02,0x43,0xb0,0xf3	@ aese q2,q1
	veor	q2,q2,q0

	vst1.8	{q2},[r1]
	bx	lr
.size	GFp_aes_hw_encrypt,.-GFp_aes_hw_encrypt
.globl	GFp_aes_hw_decrypt
.hidden	GFp_aes_hw_decrypt
.type	GFp_aes_hw_decrypt,%function
.align	5
GFp_aes_hw_decrypt:
	ldr	r3,[r2,#240]
	vld1.32	{q0},[r2]!
	vld1.8	{q2},[r0]
	sub	r3,r3,#2
	vld1.32	{q1},[r2]!

.Loop_dec:
.byte	0x40,0x43,0xb0,0xf3	@ aesd q2,q0
.byte	0xc4,0x43,0xb0,0xf3	@ aesimc q2,q2
	vld1.32	{q0},[r2]!
	subs	r3,r3,#2
.byte	0x42,0x43,0xb0,0xf3	@ aesd q2,q1
.byte	0xc4,0x43,0xb0,0xf3	@ aesimc q2,q2
	vld1.32	{q1},[r2]!
	bgt	.Loop_dec

.byte	0x40,0x43,0xb0,0xf3	@ aesd q2,q0
.byte	0xc4,0x43,0xb0,0xf3	@ aesimc q2,q2
	vld1.32	{q0},[r2]
.byte	0x42,0x43,0xb0,0xf3	@ aesd q2,q1
	veor	q2,q2,q0

	vst1.8	{q2},[r1]
	bx	lr
.size	GFp_aes_hw_decrypt,.-GFp_aes_hw_decrypt
.globl	GFp_aes_hw_ctr32_encrypt_blocks
.hidden	GFp_aes_hw_ctr32_encrypt_blocks
.type	GFp_aes_hw_ctr32_encrypt_blocks,%function
.align	5
GFp_aes_hw_ctr32_encrypt_blocks:
	mov	ip,sp
	stmdb	sp!,{r4,r5,r6,r7,r8,r9,r10,lr}
	vstmdb	sp!,{d8,d9,d10,d11,d12,d13,d14,d15}            @ ABI specification says so
	ldr	r4, [ip]		@ load remaining arg
	ldr	r5,[r3,#240]

	ldr	r8, [r4, #12]
	vld1.32	{q0},[r4]

	vld1.32	{q8,q9},[r3]		@ load key schedule...
	sub	r5,r5,#4
	mov	r12,#16
	cmp	r2,#2
	add	r7,r3,r5,lsl#4	@ pointer to last 5 round keys
	sub	r5,r5,#2
	vld1.32	{q12,q13},[r7]!
	vld1.32	{q14,q15},[r7]!
	vld1.32	{q7},[r7]
	add	r7,r3,#32
	mov	r6,r5
	movlo	r12,#0
#ifndef __ARMEB__
	rev	r8, r8
#endif
	vorr	q1,q0,q0
	add	r10, r8, #1
	vorr	q10,q0,q0
	add	r8, r8, #2
	vorr	q6,q0,q0
	rev	r10, r10
	vmov.32	d3[1],r10
	bls	.Lctr32_tail
	rev	r12, r8
	sub	r2,r2,#3		@ bias
	vmov.32	d21[1],r12
	b	.Loop3x_ctr32

.align	4
.Loop3x_ctr32:
.byte	0x20,0x03,0xb0,0xf3	@ aese q0,q8
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x20,0x23,0xb0,0xf3	@ aese q1,q8
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
.byte	0x20,0x43,0xf0,0xf3	@ aese q10,q8
.byte	0xa4,0x43,0xf0,0xf3	@ aesmc q10,q10
	vld1.32	{q8},[r7]!
	subs	r6,r6,#2
.byte	0x22,0x03,0xb0,0xf3	@ aese q0,q9
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x22,0x23,0xb0,0xf3	@ aese q1,q9
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
.byte	0x22,0x43,0xf0,0xf3	@ aese q10,q9
.byte	0xa4,0x43,0xf0,0xf3	@ aesmc q10,q10
	vld1.32	{q9},[r7]!
	bgt	.Loop3x_ctr32

.byte	0x20,0x03,0xb0,0xf3	@ aese q0,q8
.byte	0x80,0x83,0xb0,0xf3	@ aesmc q4,q0
.byte	0x20,0x23,0xb0,0xf3	@ aese q1,q8
.byte	0x82,0xa3,0xb0,0xf3	@ aesmc q5,q1
	vld1.8	{q2},[r0]!
	vorr	q0,q6,q6
.byte	0x20,0x43,0xf0,0xf3	@ aese q10,q8
.byte	0xa4,0x43,0xf0,0xf3	@ aesmc q10,q10
	vld1.8	{q3},[r0]!
	vorr	q1,q6,q6
.byte	0x22,0x83,0xb0,0xf3	@ aese q4,q9
.byte	0x88,0x83,0xb0,0xf3	@ aesmc q4,q4
.byte	0x22,0xa3,0xb0,0xf3	@ aese q5,q9
.byte	0x8a,0xa3,0xb0,0xf3	@ aesmc q5,q5
	vld1.8	{q11},[r0]!
	mov	r7,r3
.byte	0x22,0x43,0xf0,0xf3	@ aese q10,q9
.byte	0xa4,0x23,0xf0,0xf3	@ aesmc q9,q10
	vorr	q10,q6,q6
	add	r9,r8,#1
.byte	0x28,0x83,0xb0,0xf3	@ aese q4,q12
.byte	0x88,0x83,0xb0,0xf3	@ aesmc q4,q4
.byte	0x28,0xa3,0xb0,0xf3	@ aese q5,q12
.byte	0x8a,0xa3,0xb0,0xf3	@ aesmc q5,q5
	veor	q2,q2,q7
	add	r10,r8,#2
.byte	0x28,0x23,0xf0,0xf3	@ aese q9,q12
.byte	0xa2,0x23,0xf0,0xf3	@ aesmc q9,q9
	veor	q3,q3,q7
	add	r8,r8,#3
.byte	0x2a,0x83,0xb0,0xf3	@ aese q4,q13
.byte	0x88,0x83,0xb0,0xf3	@ aesmc q4,q4
.byte	0x2a,0xa3,0xb0,0xf3	@ aese q5,q13
.byte	0x8a,0xa3,0xb0,0xf3	@ aesmc q5,q5
	veor	q11,q11,q7
	rev	r9,r9
.byte	0x2a,0x23,0xf0,0xf3	@ aese q9,q13
.byte	0xa2,0x23,0xf0,0xf3	@ aesmc q9,q9
	vmov.32	d1[1], r9
	rev	r10,r10
.byte	0x2c,0x83,0xb0,0xf3	@ aese q4,q14
.byte	0x88,0x83,0xb0,0xf3	@ aesmc q4,q4
.byte	0x2c,0xa3,0xb0,0xf3	@ aese q5,q14
.byte	0x8a,0xa3,0xb0,0xf3	@ aesmc q5,q5
	vmov.32	d3[1], r10
	rev	r12,r8
.byte	0x2c,0x23,0xf0,0xf3	@ aese q9,q14
.byte	0xa2,0x23,0xf0,0xf3	@ aesmc q9,q9
	vmov.32	d21[1], r12
	subs	r2,r2,#3
.byte	0x2e,0x83,0xb0,0xf3	@ aese q4,q15
.byte	0x2e,0xa3,0xb0,0xf3	@ aese q5,q15
.byte	0x2e,0x23,0xf0,0xf3	@ aese q9,q15

	veor	q2,q2,q4
	vld1.32	{q8},[r7]!	@ re-pre-load rndkey[0]
	vst1.8	{q2},[r1]!
	veor	q3,q3,q5
	mov	r6,r5
	vst1.8	{q3},[r1]!
	veor	q11,q11,q9
	vld1.32	{q9},[r7]!	@ re-pre-load rndkey[1]
	vst1.8	{q11},[r1]!
	bhs	.Loop3x_ctr32

	adds	r2,r2,#3
	beq	.Lctr32_done
	cmp	r2,#1
	mov	r12,#16
	moveq	r12,#0

.Lctr32_tail:
.byte	0x20,0x03,0xb0,0xf3	@ aese q0,q8
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x20,0x23,0xb0,0xf3	@ aese q1,q8
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
	vld1.32	{q8},[r7]!
	subs	r6,r6,#2
.byte	0x22,0x03,0xb0,0xf3	@ aese q0,q9
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x22,0x23,0xb0,0xf3	@ aese q1,q9
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
	vld1.32	{q9},[r7]!
	bgt	.Lctr32_tail

.byte	0x20,0x03,0xb0,0xf3	@ aese q0,q8
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x20,0x23,0xb0,0xf3	@ aese q1,q8
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
.byte	0x22,0x03,0xb0,0xf3	@ aese q0,q9
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x22,0x23,0xb0,0xf3	@ aese q1,q9
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
	vld1.8	{q2},[r0],r12
.byte	0x28,0x03,0xb0,0xf3	@ aese q0,q12
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x28,0x23,0xb0,0xf3	@ aese q1,q12
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
	vld1.8	{q3},[r0]
.byte	0x2a,0x03,0xb0,0xf3	@ aese q0,q13
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x2a,0x23,0xb0,0xf3	@ aese q1,q13
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
	veor	q2,q2,q7
.byte	0x2c,0x03,0xb0,0xf3	@ aese q0,q14
.byte	0x80,0x03,0xb0,0xf3	@ aesmc q0,q0
.byte	0x2c,0x23,0xb0,0xf3	@ aese q1,q14
.byte	0x82,0x23,0xb0,0xf3	@ aesmc q1,q1
	veor	q3,q3,q7
.byte	0x2e,0x03,0xb0,0xf3	@ aese q0,q15
.byte	0x2e,0x23,0xb0,0xf3	@ aese q1,q15

	cmp	r2,#1
	veor	q2,q2,q0
	veor	q3,q3,q1
	vst1.8	{q2},[r1]!
	beq	.Lctr32_done
	vst1.8	{q3},[r1]

.Lctr32_done:
	vldmia	sp!,{d8,d9,d10,d11,d12,d13,d14,d15}
	ldmia	sp!,{r4,r5,r6,r7,r8,r9,r10,pc}
.size	GFp_aes_hw_ctr32_encrypt_blocks,.-GFp_aes_hw_ctr32_encrypt_blocks
#endif
#endif
#endif  // !OPENSSL_NO_ASM
