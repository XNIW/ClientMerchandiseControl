package com.xniw.clientmerchandisecontrol

/** Barriera del journal cifrato per flutter_secure_storage 10.3.1.
 * Le chiavi avvolte e i marker algoritmo devono precedere il payload durevole.
 * Nessun indirizzo, owner o intent attraversa il canale nativo.
 */
internal object AddressCreationDurability {
    const val CHANNEL = "com.xniw.clientmerchandisecontrol/address_creation_durability"
    const val NAMESPACE = "cmc_address_creation_v1"
    const val MARKER = "cmc_durability_barrier"

    fun flush(commit: (String) -> Boolean): Boolean {
        for (name in listOf(
            "FlutterSecureKeyStorage:$NAMESPACE",
            "FlutterSecureStorageConfiguration:$NAMESPACE",
            NAMESPACE,
        )) {
            if (!commit(name)) return false
        }
        return true
    }
}
