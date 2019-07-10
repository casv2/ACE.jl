
using SHIPs, JuLIP, BenchmarkTools, LinearAlgebra

function randR()
   R = rand(JVecF) .- 0.5
   return (0.9 + 2 * rand()) * R/norm(R)
end
randR(N) = [ randR() for n=1:N ]
randcoeffs(B) = rand(length(B)) .* (1:length(B)).^(-2)

trans = PolyTransform(2, 1.0)
BB = [ SHIPBasis(TotalDegree(20, 1.0), 2, trans, 2, 0.5, 3.0),
       SHIPBasis(TotalDegree(20, 1.5), 3, trans, 2, 0.5, 3.0),
       SHIPBasis(TotalDegree(15, 1.5), 4, trans, 2, 0.5, 3.0) ]

Nat = 50
Rs = randR(Nat)
btmp = SHIPs.alloc_temp(BB[1])
@info("profile precomputation of A")
@btime SHIPs.precompute_A!($btmp, $(BB[1]), $Rs)
# @btime SHIPs.precompute_A!($(BB[1]), $Rs, $btmp)

@info("profile basis and ship computation")
for n = 2:4
   @info("  body-order $(n+1):")
   Rs = randR(Nat)
   B = BB[n-1]
   coeffs = randcoeffs(B)
   🚢 = SHIP(B, coeffs)
   b = SHIPs.alloc_B(B)
   btmp = SHIPs.alloc_temp(B)
   tmp = SHIPs.alloc_temp(🚢)
   @info("     evaluate a site energy:")
   print("         SHIPBasis: "); @btime SHIPs.eval_basis!($b, $B, $Rs, $tmp)
   print("         SHIP     : "); @btime SHIPs.evaluate!($🚢, $Rs, $tmp)

   tmp = SHIPs.alloc_temp_d(🚢, Rs)
   dEs = zeros(JVecF, length(Rs))
   db = SHIPs.alloc_dB(B, Rs)
   dbtmp = SHIPs.alloc_temp_d(B, Rs)

   @info("     site energy gradient:")
   store = SHIPs.alloc_temp_d(🚢, Rs)
   print("         SHIPBasis: "); @btime SHIPs.eval_basis_d!($b, $db, $B, $Rs, $dbtmp)
   print("         SHIP     : "); @btime SHIPs.evaluate_d!($dEs, $🚢, $Rs, $store)
end


# ##
# Nat = 50
# Rs = randR(Nat)
# B = SHIPBasis(4, 15, 1.5, trans, 2, 0.5, 3.0)
# coeffs = randcoeffs(B)
# 🚢 = SHIP(B, coeffs)
# tmp = SHIPs.alloc_temp(🚢)
# tmp_d = SHIPs.alloc_temp_d(🚢, Rs)
# dEs = zeros(JVecF, length(Rs))
# SHIPs.evaluate_d!(dEs, 🚢, Rs, tmp_d)
#
# using Profile, ProfileView
# Profile.clear()
# @profile begin
#    for n = 1:1000
#       SHIPs.evaluate_d!(dEs, 🚢, Rs, tmp_d)
#    end
# end
# Profile.print()
# ProfileView.view()
