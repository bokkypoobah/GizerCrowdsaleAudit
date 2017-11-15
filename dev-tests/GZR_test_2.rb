require_relative "GZR_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

@sl.h1 'Preliminary actions'

###

@sot.txt 'Set wallets'

@sot.own :set_wallet,            @wallet_account
@sot.own :set_redemption_wallet, @redemption_account
@sot.own :set_whitelist_wallet,  @whitelist_account

@sot.exp :wallet,            @sot.strip0x(@wallet_account)
@sot.exp :redemption_wallet, @sot.strip0x(@redemption_account)
@sot.exp :whitelist_wallet,  @sot.strip0x(@whitelist_account)

@sot.do

###

@sot.txt 'Add account 2 to whitelist'
@sot.add :add_to_whitelist, @whitelist_key, @a[2]
@sot.exp :whitelist, @a[2], true
@sot.do
 

###############################################################################

@sl.h1 'Before presale'

###

@sot.txt 'Private sale contributions' # token rate 1150 per eth

@sot.own :private_sale_contribution, @a[1],   10 * @E18
@sot.own :private_sale_contribution, @a[2],  100 * @E18
@sot.own :private_sale_contribution, @a[3], 1000 * @E18 # over the limit

@sot.exp :balance_of, @a[1],  11500 * @E6,  11500 * @E6
@sot.exp :balance_of, @a[2], 115000 * @E6, 115000 * @E6
@sot.exp :balance_of, @a[3],      0 * @E6,      0 * @E6

@sot.do

###

@sot.txt 'Some minting (ok) and an early contribution (throws)'

@sot.own :mint_reserve, @a[1], 100000 * @E6
@sot.own :mint_team,    @a[1],  50000 * @E6

@sot.snd @k[1], 10 # this contribution gets rejected

@sot.exp :balance_of, @a[1], 161500 * @E6, 150000 * @E6

@sot.do


###############################################################################

@sl.h1 'Presale'

epoch = @sot.var :date_presale_start
jump_to(epoch, 'presale')

#

@sot.txt 'Some presale contributions'

@sot.snd @k[1], 1
@sot.snd @k[2], 10

@sot.exp :balance_of, @a[1], nil, 1150 * @E6
@sot.exp :balance_of, @a[2], nil, 11500 * @E6
@sot.exp :presale_contributor_count, 2, 2

@sot.exp :locked_balance, @a[1], 51150 * @E6, nil
@sot.exp :locked_balance, @a[2], 0, nil

@sot.do

###


###############################################################################

@sl.h1 'After presale'

epoch = @sot.var :date_presale_end
jump_to(epoch, 'after presale')

###


###############################################################################

@sl.h1 'ICO'

epoch = @sot.var :date_ico_start
jump_to(epoch, 'ico')

###

@sot.txt 'Reclaim funds - fails'
@sot.add :reclaim_funds, @k[1]
@sot.exp :balance_of, @a[1], nil, 0
@sot.do


###############################################################################

@sl.h1 'After ICO'

epoch = @sot.var :date_ico_end
jump_to(epoch, 'after ico')

###

@sot.txt 'Declaring ICO finished fails'

@sot.own :declare_ico_finished
@sot.exp :ico_finished, false

@sot.own :make_tradeable
@sot.exp :tradeable, false

@sot.do

###

@sot.txt 'Reclaim funds - ok'
@sot.add :reclaim_funds, @k[1]
@sot.exp :balance_of, @a[1], nil, -1150 * @E6
@sot.exp :get_balance, @a[1], nil, 1 * @E18
@sot.do

###

@sot.txt 'owner clawback - not yet'
@sot.own :owner_clawback
@sot.exp :get_balance, @contract_address, 10 * @E18, 0
@sot.do

###############################################################################

@sl.h1 'After lockup end date'

epoch = @sot.var :lockup_end_date
jump_to(epoch, 'after lockup end')

###

@sot.txt 'owner clawback - ok'
@sot.own :owner_clawback
@sot.exp :get_balance, @contract_address, 0, nil
@sot.exp :get_balance, @wallet_account, nil, 10 * @E18
@sot.do

###

@sot.txt 'Transfers - no'
@sot.add :transfer, @k[1], @a[2], 1 * @E6
@sot.add :transfer, @k[2], @a[1], 10 * @E6
@sot.exp :balance_of,  @a[1], nil, 0
@sot.exp :balance_of,  @a[2], nil, 0
@sot.do

###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"
