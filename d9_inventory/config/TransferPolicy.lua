TransferPolicy = TransferPolicy or {}

TransferPolicy.limits = {
    max_distance = Config and Config.DistanceGive or 3.0,
    max_amount = ServerConfig and ServerConfig.Restrictions and ServerConfig.Restrictions.MaxItemTransfer or 1000,
}

TransferPolicy.messages = {
    TOO_FAR = '~r~ผู้เล่นอยู่ไกลเกินไป',
    INVALID_AMOUNT = '~r~จำนวนไอเทมไม่ถูกต้อง',
    AMOUNT_EXCEEDED = '~r~จำนวนสูงสุดต่อครั้งคือ %s',
    NOT_ENOUGH_ITEM = '~r~คุณมีไอเทมไม่เพียงพอ',
    GIVE_ITEM_OK = '~g~ให้ไอเทมสำเร็จ',
    RECEIVE_ITEM = '~g~ได้รับไอเทมจาก %s',
    NOT_ENOUGH_MONEY = '~r~เงินสดไม่เพียงพอ',
    GIVE_MONEY_OK = '~g~ให้เงินสดสำเร็จ',
    RECEIVE_MONEY = '~g~ได้รับเงินสดจาก %s',
    NOT_ENOUGH_BLACK_MONEY = '~r~เงินดำไม่เพียงพอ',
    GIVE_BLACK_MONEY_OK = '~g~ให้เงินดำสำเร็จ',
    RECEIVE_BLACK_MONEY = '~g~ได้รับเงินดำจาก %s',
    NO_WEAPON = '~r~คุณไม่มีอาวุธชิ้นนี้',
    GIVE_WEAPON_OK = '~g~ให้อาวุธสำเร็จ',
    RECEIVE_WEAPON = '~g~ได้รับอาวุธจาก %s',
    NO_PLATE = '~r~ไม่พบข้อมูลป้ายทะเบียนรถ',
    WELFARE_BLOCK = '~r~รถคันนี้ไม่สามารถเทรดผ่าน Trade Car Welfare ได้',
}

TransferPolicy.actions = {
    item_standard = "ITEM",
    item_account = "ACCOUNT",
    item_weapon = "WEAPON",
    item_key = "VEHICLE_KEY",
}
